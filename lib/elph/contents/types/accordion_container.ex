defmodule Elph.Contents.Types.AccordionContainer do
  @moduledoc """
  The AccordionContainer is a type of container used to visualize its child contents.
  It isn't a whole accordion, but instead it's an accordion row. It's childs are it's
  content, which can either be shown or hidden. The title is the headline that is
  shown for this row and the default_open flag is there to save it's default state
  with either the children hidden or visible.
  """
  use Ecto.Schema
  use Elph.Contents.ContentType

  import Ecto.Changeset

  content_schema "accordion_container_contents" do
    field :default_open, :boolean
    field :title, :string, default: ""
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, [:default_open, :title])
  end
end
