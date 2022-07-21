defmodule Elph.Contents.Content do
  @moduledoc """
  Content is the abstract representation of the datastructure the user is
  sending and receiving from the frontends. It is also the "base class" for
  every other content type. Content subtype changesets are called from here.
  """

  use Ecto.Schema
  import Ecto.Changeset

  def repo, do: Application.get_env(:elph, :repo)
  def types, do: Application.get_env(:elph, :types, Elph.Contents.DefaultTypes)

  @primary_key {:id, :id, autogenerate: true}
  embedded_schema do
    field :name, :string
    field :shared, :boolean, default: false
    field :type, :string

    embeds_many :children, __MODULE__, on_replace: :delete
    field :subtype_changeset_map, :map
  end

  def changeset(content, %{__struct__: _} = attrs) do
    changeset(content, Map.from_struct(attrs))
  end

  def changeset(content, attrs) do
    content
    |> cast_and_validate_basics(attrs)
    |> cast_subtype(attrs)
    |> cast_embed(:children)
  end

  def cast_and_validate_basics(content, attrs) do
    content
    |> cast(attrs, [:id, :name, :shared, :type])
    |> validate_required([:type])
    |> validate_has_name_if_shared()
  end

  def validate_has_name_if_shared(changeset) do
    if get_field(changeset, :shared) == true and get_field(changeset, :name) == nil do
      add_error(changeset, :name, "required if shared")
    else
      changeset
    end
  end

  def cast_subtype(changeset, attrs) do
    type = get_field(changeset, :type)

    module = types().get_module(type)

    changeset =
      case module do
        nil ->
          add_error(changeset, :type, "is invalid")

        _ ->
          struct =
            case Map.get(attrs, "id") || Map.get(attrs, :id) do
              nil ->
                module.__struct__

              id ->
                repo().get!(module, id)
            end

          case subtype_changeset = apply(module, :changeset, [struct, attrs]) do
            %{valid?: true} ->
              subtype_changeset_map = Map.from_struct(subtype_changeset)
              put_change(changeset, :subtype_changeset_map, subtype_changeset_map)

            %{valid?: false} ->
              %{changeset | errors: changeset.errors ++ subtype_changeset.errors, valid?: false}
          end
      end

    changeset
  end
end
