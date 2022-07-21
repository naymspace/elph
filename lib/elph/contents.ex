defmodule Elph.Contents do
  @moduledoc """
  The Contents context. This is the main module of the elph library. It provides functions to
  work with contents.
  """

  import Ecto.Query, warn: false
  def repo, do: Application.get_env(:elph, :repo)
  def types, do: Application.get_env(:elph, :types, Elph.Contents.DefaultTypes)
  def callbacks, do: Application.get_env(:elph, :callbacks, Elph.Contents.DefaultCallbacks)
  alias Elph.Contents.Content
  alias Elph.Contents.DbContent
  alias Elph.Contents.MediaContent
  alias Elph.Contents.MediaUpload

  alias Elph.MediaProcessing

  require Logger

  @doc """
  Returns the list of contents without relations between them.
  The children arrays are empty here

  ## Examples

      iex> list_contents()
      [%Content{}, ...]

  """
  def list_contents(opts \\ []) do
    action = Keyword.get(opts, :action, :index)

    contents =
      opts
      |> Keyword.get(:show_all, false)
      |> DbContent.list_contents(action)

    contents =
      case type = Keyword.get(opts, :type) do
        nil -> contents
        _ -> Enum.filter(contents, fn content -> Enum.any?(type, &(&1 == content.type)) end)
      end

    contents =
      case search = Keyword.get(opts, :search) do
        query when is_binary(query) ->
          Enum.filter(contents, fn content ->
            String.contains?(String.downcase(content.name), String.downcase(search))
          end)

        _ ->
          contents
      end

    page_size = Keyword.get(opts, :page_size, 0)

    if page_size > 0 do
      total_pages = ceil(Enum.count(contents) / page_size)
      current_page = opts |> Keyword.get(:page, 1) |> min(total_pages) |> max(1)

      page_start_index = page_size * (current_page - 1)

      paged_contents = Enum.slice(contents, page_start_index, page_size)

      {paged_contents, current_page, total_pages}
    else
      contents
    end
  end

  @doc """
  Gets a single content.

  Raises `Ecto.NoResultsError` if the Content does not exist.

  ## Examples

      iex> get_content!(123)
      %Content{}

      iex> get_content!(456)
      ** (Ecto.NoResultsError)

  """

  def get_content!(id, action \\ :show) do
    DbContent.get_content!(id, action)
  end

  @doc """
  Creates and updates a content-tree.
  Contents with an id will be updated, contents without an id are treated as new

  ## TODO: Examples

      iex> persist_content(content, %{field: new_value})
      {:ok, %Content{}}

      iex> persist_content(content, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def persist_content(attrs) do
    repo().transaction(fn ->
      changeset = validate_content(attrs)
      persist_content_changeset(changeset)
    end)
  end

  def validate_content(attrs) do
    Content.changeset(%Content{}, attrs)
  end

  @doc """
  Creates a specific media_content. I.e. audio_content, image_content, etc.

  ## Examples

      iex> create_media_content(%{field: value})
      {:ok, %Content{}}

      iex> create_media_content(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_media_content(attrs) do
    case media_changeset = MediaUpload.changeset(%MediaUpload{}, attrs) do
      %{valid?: false} ->
        {:error, media_changeset}

      %{valid?: true} ->
        media = Ecto.Changeset.apply_changes(media_changeset)

        subtype_module =
          case media.type do
            :image -> Elph.Contents.Types.Image
            :video -> Elph.Contents.Types.Video
            :audio -> Elph.Contents.Types.Audio
          end

        subtype_changeset =
          subtype_module.__struct__
          |> (&subtype_module.create_changeset(&1, Map.from_struct(media))).()
          |> (&subtype_module.create_thumbnails(&1)).()

        content_attrs = %{type: Atom.to_string(media.type), shared: true, name: media.name}

        persist_result =
          repo().transaction(fn ->
            %Content{}
            |> Content.cast_and_validate_basics(content_attrs)
            |> Ecto.Changeset.put_change(
              :subtype_changeset_map,
              Map.from_struct(subtype_changeset)
            )
            |> persist_content_changeset()
          end)

        case persist_result do
          {:ok, content} ->
            convert_media_in_background(subtype_module, content)

          {:error, _} ->
            MediaContent.delete_from_disk(media)
        end

        persist_result
    end
  end

  defp persist_content_changeset(changeset) do
    case changeset do
      %{valid?: false} ->
        repo().rollback(changeset)

      %{valid?: true} ->
        result =
          changeset
          |> Ecto.Changeset.apply_changes()
          |> DbContent.persist_content!()

        with %DbContent{id: id} <- result do
          cleanup_orphaned_contents()
          get_content!(id)
        end
    end
  end

  defp convert_media_in_background(subtype_module, %{id: content_id} = content) do
    subtype_module
    |> apply(:convert_media_in_background_tasks, [content])
    |> Enum.each(fn {key, convert_fn} ->
      MediaProcessing.enqueue_background_conversion(fn ->
        with {:ok, path} <- convert_fn.() do
          save_convert_media_result(subtype_module, content_id, key, Path.basename(path))
        end

        conversion_key =
          key |> Atom.to_string() |> (&(&1 <> "_conversion")).() |> String.to_atom()

        save_convert_media_result(subtype_module, content_id, conversion_key, false)
      end)
    end)
  end

  defp save_convert_media_result(schema, id, key, value) do
    repo().transaction(fn ->
      schema
      |> repo().get(id)
      |> Ecto.Changeset.cast(%{key => value}, [key])
      |> repo().update()
    end)
  end

  @doc """
  Deletes a Content.

  ## Examples

      iex> delete_content(content)
      :ok

      iex> delete_content(content)
      {:error, reason}

  """
  def delete_content(content) do
    with {:ok, deleted_content} <-
           repo().transaction(fn ->
             DbContent.delete_content!(content)
           end) do
      [deleted_content | delete_orphaned_contents()]
      |> cleanup_after_deleted_contents()

      :ok
    end
  end

  @doc """
  Contents that aren't `shared` and have no ancestor that is `shared` are not being used anymore.
  This function deletes them from the database.
  """
  def cleanup_orphaned_contents do
    delete_orphaned_contents()
    |> cleanup_after_deleted_contents()
  end

  defp cleanup_after_deleted_contents(contents) do
    global_rerun = run_global_after_cleanup_callbacks(contents)

    content_type_rerun = run_content_type_after_cleanup_callbacks(contents)

    with true <- global_rerun || content_type_rerun do
      cleanup_orphaned_contents()
    end
  end

  defp run_global_after_cleanup_callbacks(contents) do
    Enum.reduce(
      callbacks().cleanup_callbacks,
      false,
      fn callback, acc ->
        rerun? = callback.(contents) == :cleanup
        acc || rerun?
      end
    )
  end

  defp run_content_type_after_cleanup_callbacks(contents) do
    Enum.reduce(
      contents,
      false,
      fn content, acc ->
        module = types().get_module(content.type)

        rerun? = module.after_delete_callback(content) == :cleanup
        acc || rerun?
      end
    )
  end

  defp delete_orphaned_contents do
    {:ok, deleted_contents} = repo().transaction(&DbContent.delete_orphaned_contents/0)
    deleted_contents
  end

  @doc """
  This function sets all contents with tht given ids to `shared: false`. This is faster then cleaning
  them up manually. They will then be garbage collected in the near future.
  """
  def unshare_contents(ids) do
    query =
      from(c in DbContent,
        where: c.id in ^ids
      )

    unshare(query)
  end

  @doc """
  This function sets all contents found within the given queryable to `shared: false`. This is faster
  then cleaning them up manually. They will then be garbage collected in the near future.
  """
  def unshare(queryable) do
    repo().update_all(queryable, set: [shared: false])
  end

  @doc """
  Calls a function for the given content tree. If the function returns a content with children, the function
  will also be called for all the children.
  """
  def map(content, func) do
    new_content = func.(content)

    atom_key? = new_content |> Map.keys() |> Enum.at(0) |> is_atom()
    children_key = if atom_key?, do: :children, else: "children"
    children = Map.get(new_content, children_key)

    case children do
      [_ | _] ->
        %{
          new_content
          | children_key => Enum.map(children, fn child -> map(child, func) end)
        }

      _ ->
        new_content
    end
  end
end
