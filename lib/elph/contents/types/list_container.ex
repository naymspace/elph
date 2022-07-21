defmodule Elph.Contents.Types.ListContainer do
  @moduledoc """
  ListContainers are the simplest of containers usable in elph. They don't have
  any more parameters then their children.
  """
  use Ecto.Schema
  use Elph.Contents.ContentType

  import Ecto.Changeset

  content_schema "list_container_contents" do
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, [])
  end
end
