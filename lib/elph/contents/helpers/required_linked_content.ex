defmodule Elph.Contents.Helper.RequiredLinkedContent do
  @moduledoc """
  This module holds the create_required_linked_content helper.
  It looks in the given changeset if a field is set. If so it does nothing.
  Otherwise it creates the new empty content and sets the linked field in the
  changeset.
  """
  import Ecto.Changeset

  def create_required_linked_content(changeset, field, empty_content) do
    case get_field(changeset, field) do
      nil ->
        case Elph.Contents.persist_content(empty_content) do
          {:ok, %{id: id}} ->
            put_change(changeset, field, id)

          _ ->
            add_error(changeset, field, "could not be created")
        end

      _ ->
        changeset
    end
  end
end
