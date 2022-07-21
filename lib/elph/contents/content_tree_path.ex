defmodule Elph.Contents.ContentTreePath do
  @moduledoc false

  # ContentTreePath is the schema used in the database to define relations
  # between contents. At the base Elph is using the closure table abstraction
  # with added functionality.
  #
  # Every node knows all his ancestors. Even himself is considered an ancestor.
  #
  # The order is only important and therefor only set for direct parent-child-
  # relationships. In the case we have a parent-child-relationship an order
  # HAS TO be set, for the relationship to be recognized as such.
  # In every other relationship (i.E. self reference or grandparent-grandchild
  # etc.) there HAS TO be no order set i.E. `nil`.

  use Ecto.Schema

  alias Elph.Contents.DbContent

  @primary_key false
  schema "content_tree_paths" do
    belongs_to :ancestor, DbContent
    belongs_to :descendant, DbContent
    field :order, :integer
  end
end
