defmodule Elph.Contents.Types.AccordionRow do
  @moduledoc """
  The AccordionRow is a type of container used to visualize its child contents.
  It represents an accordion row. Its childs are the content, which can either be shown
  or hidden. The title is the headline that is shown for this row and the default_open
  flag is there to save its default state with either the children hidden or visible.
  """
  use Ecto.Schema
  use Elph.Contents.ContentType

  import Ecto.Changeset

  content_schema "accordion_row_contents" do
    field :default_open, :boolean
    field :title, :string, default: ""
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, [:default_open, :title])
  end
end
