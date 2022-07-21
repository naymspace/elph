defmodule Elph.Contents.Types.Html do
  @moduledoc """
  This content type is for saving html.
  """
  use Ecto.Schema
  use Elph.Contents.ContentType

  import Ecto.Changeset

  content_schema "html_contents" do
    field :html, :string
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, [:html])
    |> validate_required([:html])
  end
end
