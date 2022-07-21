defmodule Elph.Contents.Types.Markdown do
  @moduledoc """
  This content type is for saving markdown.
  """
  use Ecto.Schema
  use Elph.Contents.ContentType

  import Ecto.Changeset

  content_schema "markdown_contents" do
    field :markdown, :string
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, [:markdown])
    |> validate_required([:markdown])
  end
end
