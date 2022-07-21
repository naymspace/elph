defmodule Elph.Contents.DbContent do
  @moduledoc false

  # DbContent is the schema that saves real contents in the database.
  # Together with ContentTreePath it represents our closure table.
  #
  # The abstract representation for this is the Content.
  #
  # This schema has all the attributes shared between all contents.
  # Specific "subclasses" (like ImageContent or GalleryContent) will use
  # DbContent by foreign key relation to this table.

  use Ecto.Schema

  alias Elph.Contents.ContentTreePath
  alias Elph.Contents.DbContent

  import Ecto.Query

  require Logger

  def repo, do: Application.get_env(:elph, :repo)
  def types, do: Application.get_env(:elph, :types, Elph.Contents.DefaultTypes)
  def content_preloads_max_depth, do: Application.get_env(:elph, :content_preloads_max_depth, 3)

  schema "contents" do
    field(:name, :string)
    field(:shared, :boolean)
    field(:type, :string)
    timestamps()
  end

  @doc """
    Returns the ancestors of `id` that aren't also ancestors of `filtered_id`
  """
  def get_filtered_ancestor_ids(id, filtered_id \\ nil) do
    notin =
      case filtered_id do
        nil ->
          []

        _ ->
          repo().all(
            from(p in ContentTreePath,
              where: p.descendant_id == ^filtered_id,
              select: p.ancestor_id
            )
          )
      end

    query =
      from(p in ContentTreePath,
        where: p.descendant_id == ^id,
        where: not (p.ancestor_id == ^id),
        where: p.ancestor_id not in ^notin,
        select: p.ancestor_id
      )

    repo().all(query)
  end

  def get_parents_ancestor_ids(id) do
    query =
      from(p1 in ContentTreePath,
        join: p2 in ContentTreePath,
        on: p1.ancestor_id == p2.descendant_id,
        where: p1.descendant_id == ^id,
        where: not is_nil(p1.order),
        select: p2.ancestor_id
      )

    repo().all(query)
  end

  def flatten_contents_tree(contents) do
    Enum.flat_map(contents, fn content ->
      [content] ++ flatten_contents_tree(content.children)
    end)
  end

  def delete_descendant_relationships(ancestor_ids) do
    query =
      from(p in ContentTreePath,
        where: p.ancestor_id in ^ancestor_ids
      )

    repo().delete_all(query)
  end

  def persist_content!(content) do
    # get content item ids
    item_ids =
      [content]
      |> flatten_contents_tree()
      |> Enum.map(& &1.id)
      |> Enum.filter(&(&1 != nil))

    # delete inner-content relationships (where ancestor_id is in itemids)
    if Enum.count(item_ids) > 0 do
      delete_descendant_relationships(item_ids)
    end

    # create/update items and create links
    persisted_content = persist_content_tree!(content)

    # return new struct
    persisted_content
  end

  defp content_to_changeset(content) do
    Ecto.Changeset.cast(
      %DbContent{id: content.id},
      %{name: content.name, shared: content.shared, type: content.type},
      [:name, :shared, :type]
    )
  end

  defp persist_single_content!(content) do
    db_changeset = content_to_changeset(content)

    %{id: content_id} =
      persisted_content =
      case content.id do
        nil -> repo().insert!(db_changeset)
        _ -> repo().update!(db_changeset)
      end

    subtype_changeset_map_with_id =
      Map.update!(content.subtype_changeset_map, :data, &Map.put(&1, :id, content_id))

    subtype_changeset = struct(%Ecto.Changeset{}, subtype_changeset_map_with_id)

    case content.id do
      nil -> repo().insert!(subtype_changeset)
      _ -> repo().update!(subtype_changeset)
    end

    persisted_content
  end

  defp insert_path!(ancestor_id, descendant_id, order \\ nil) do
    path = %ContentTreePath{
      ancestor_id: ancestor_id,
      descendant_id: descendant_id,
      order: order
    }

    repo().insert!(path, on_conflict: :nothing)
  end

  _doc = """
    inserts/updates a content with its children into the database and creates
    links for them

    - content: the element, that should be persisted (with its children)

    - parent_id: the inner-tree parent of the current content-node.
    The Root of the persisted tree has no parent and therefor also no order.

    - order: the position of the current element in his parents children-list.
    Should probably only be set by recursion.
  """

  defp persist_content_tree!(
         content,
         parent_id \\ nil,
         order \\ nil
       ) do
    # insert self
    %{id: root_id} = root = persist_single_content!(content)

    # insert self-link
    insert_path!(root_id, root_id)

    # insert links to ancestors
    if !is_nil(parent_id) do
      ancestor_ids = [parent_id | get_filtered_ancestor_ids(parent_id, root_id)]

      insert_links_to_ancestors(root_id, ancestor_ids, order)
    end

    # call recursive
    content.children
    |> Enum.with_index()
    |> Enum.each(fn {child, index} ->
      persist_content_tree!(child, root_id, index)
    end)

    # return self
    root
  end

  defp insert_links_to_ancestors(root_id, ancestor_ids, order) do
    ancestor_ids
    |> Enum.with_index()
    |> Enum.each(fn {ancestor_id, index} ->
      order =
        if index == 0 do
          order
        else
          nil
        end

      insert_path!(ancestor_id, root_id, order)
    end)
  end

  defp base_content_tree_query(id) do
    from(p1 in ContentTreePath,
      join: p2 in ContentTreePath,
      on: p1.descendant_id == p2.ancestor_id,
      join: c in DbContent,
      as: :content,
      on: c.id == p2.descendant_id,
      where: p1.ancestor_id == ^id and (not is_nil(p2.order) or p2.descendant_id == ^id)
    )
  end

  _doc = """
  Reads the whole subtree under the node id from the database.
  The query goes something like:
  - get every node, thats a descendant of `id`
  - join those with the treeroutes where they are descendants
  - and filter those by having an order (then the relation is a parent-child one)
  - or take the self-reference of `id` to add the root
  - join this with the contents (TODO: is this needed later, when they have no attributes?)

  Returns a list of all DbContents with added parentId and order, that we can build into a tree then

  ## Examples

      iex> get_content!(49)
      [%Elph.Contents.DbContent{..., dummy: "parent", id: 49, ..., order: nil, parent_id: 49},
       %Elph.Contents.DbContent{..., dummy: "child1", id: 50, ..., order: 0, parent_id: 49},
       %Elph.Contents.DbContent{..., dummy: "grandchild1.1", id: 51, ..., order: 0, parent_id: 50}]

  """

  defp query_content!(id) do
    query =
      from([p1, p2, c] in base_content_tree_query(id),
        select: %{
          id: c.id,
          name: c.name,
          shared: c.shared,
          type: c.type,
          parent_id: p2.ancestor_id,
          order: p2.order
        }
      )

    case repo().all(query) do
      [] ->
        raise Ecto.NoResultsError, queryable: query

      result ->
        result
    end
  end

  def list_contents(show_all, action) do
    base_query =
      from(c in DbContent,
        as: :content,
        select: %{
          id: c.id,
          name: c.name,
          shared: c.shared,
          type: c.type
        }
      )

    query = if show_all, do: base_query, else: where(base_query, [content: c], c.shared == true)
    query |> repo().all() |> load_subtype_data(action)
  end

  defp load_subtype_data(contents, action, depth \\ 0) do
    subtype_ids =
      Enum.reduce(contents, %{}, fn content, acc ->
        Map.put(acc, content.type, Map.get(acc, content.type, []) ++ [content.id])
      end)

    subtype_data =
      subtype_ids
      |> Enum.map(&fetch_single_subtype(&1, action, depth))
      |> Enum.concat()
      |> Enum.map(fn content -> {content.id, content} end)
      |> Map.new()

    Enum.map(contents, fn content ->
      Map.merge(Map.get(subtype_data, content.id, %{}), content)
    end)
  end

  defp fetch_single_subtype({subtype, ids}, action, depth) do
    module = types().get_module(subtype)
    query = from(s in module, where: s.id in ^ids)

    preloads = module.preloads(action)
    content_preloads = module.content_preloads(action)

    query
    |> repo().all()
    |> repo().preload(preloads)
    |> preload_contents(content_preloads, action, depth)
  end

  defp preload_contents(contents, preload, action, depth) when is_atom(preload) do
    preload_contents(contents, [preload], action, depth)
  end

  defp preload_contents(contents, preloads, action, depth) when is_list(preloads) do
    if depth < content_preloads_max_depth() do
      Enum.reduce(preloads, contents, &preload_contents_single_preload(&1, &2, action, depth))
    else
      Logger.warn(":content_preloads_max_depth reached. Possible cycle detected")
      contents
    end
  end

  defp preload_contents(_, _, _, _) do
    raise ArgumentError, message: "contents_preload has to be :atom or [:atom1, :atom2]"
  end

  defp preload_contents_single_preload(preload_key, contents, action, depth) do
    Enum.map(contents, &maybe_preload_one(preload_key, &1, action, depth))
  end

  defp maybe_preload_one(preload_key, content, action, depth) do
    case Map.get(content, preload_key) do
      %Ecto.Association.NotLoaded{} -> preload_one(preload_key, content, action, depth)
      _ -> content
    end
  end

  defp preload_one(preload_key, content, action, depth) do
    ecto_preloaded =
      content
      |> repo().preload(preload_key)
      |> Map.get(preload_key)

    preloaded =
      case ecto_preloaded do
        p when is_list(p) -> Enum.map(ecto_preloaded, &get_content!(&1.id, action, depth + 1))
        %{} -> get_content!(ecto_preloaded.id, action, depth + 1)
        nil -> nil
      end

    Map.put(content, preload_key, preloaded)
  end

  defp filter_content(content) do
    Map.drop(content, [:children, :order, :parent_id])
  end

  defp to_content_tree(db_contents) do
    root = db_contents |> Enum.find(nil, &(&1.parent_id == &1.id))
    Map.merge(filter_content(root), %{children: to_content_tree_children(db_contents, root.id)})
  end

  defp to_content_tree_children(db_contents, parent_id) do
    db_contents
    |> Enum.filter(&(&1.parent_id == parent_id && &1.order != nil))
    |> Enum.sort(&(&1.order <= &2.order))
    |> Enum.map(fn tree_elem ->
      Map.merge(filter_content(tree_elem), %{
        children: to_content_tree_children(db_contents, tree_elem.id)
      })
    end)
  end

  def get_content!(id, action, depth \\ 0) do
    id |> query_content!() |> load_subtype_data(action, depth) |> to_content_tree()
  end

  def delete_content!(content) do
    delete_db_content(content.id)

    content
    |> Map.get(:children, [])
    |> Enum.each(&update_child_paths/1)

    Map.delete(content, :children)
  end

  defp delete_db_content(id) do
    DbContent |> repo().get!(id) |> repo().delete()

    query =
      from(ctp in ContentTreePath,
        where: ctp.ancestor_id == ^id or ctp.descendant_id == ^id
      )

    repo().delete_all(query)
  end

  defp update_child_paths(content) do
    content.id
    |> get_parents_ancestor_ids()
    |> delete_ancestors_not_in(content.id)

    Enum.map(content.children, &update_child_paths/1)
  end

  defp delete_ancestors_not_in(ancestor_ids, descendant_id) do
    query =
      from(ctp in ContentTreePath,
        where: ctp.ancestor_id not in ^ancestor_ids,
        where: ctp.ancestor_id != ^descendant_id,
        where: ctp.descendant_id == ^descendant_id
      )

    repo().delete_all(query)
  end

  def delete_orphaned_contents do
    parented_query =
      from(c in DbContent,
        join: ctp in ContentTreePath,
        on: ctp.ancestor_id == c.id,
        where: c.shared,
        select: ctp.descendant_id
      )

    parented_ids = repo().all(parented_query)

    orphaned_query =
      from(c in DbContent,
        as: :content,
        where: c.id not in ^parented_ids,
        select: %{
          id: c.id,
          name: c.name,
          shared: c.shared,
          type: c.type
        }
      )

    orphaned_content = orphaned_query |> repo().all() |> load_subtype_data(:delete)
    orphaned_content_ids = Enum.map(orphaned_content, &Map.get(&1, :id))

    repo().delete_all(
      from(ctp in ContentTreePath,
        where:
          ctp.ancestor_id in ^orphaned_content_ids or ctp.descendant_id in ^orphaned_content_ids
      )
    )

    repo().delete_all(
      from(c in DbContent,
        where: c.id in ^orphaned_content_ids
      )
    )

    orphaned_content
  end
end
