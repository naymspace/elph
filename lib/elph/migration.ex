defmodule Elph.Migration do
  @moduledoc """
  This module provides macros to help you with creating easier migrations for your custom
  content types.

  After creating your schema (and its migration) via
  `mix phx.gen.schema Contents.Types.Markdown markdown_contents markdown:text`

  - Add `use Elph.Migration` below `use Ecto.Migration`
  - In the `create table` call add `add_content_field()` and remove the `timestamps()`.
  """
  defmacro add_content_field do
    quote do
      add(
        :content_id,
        references(:contents, on_delete: :delete_all),
        null: false,
        primary_key: true
      )
    end
  end

  defmacro add_media_fields do
    quote do
      add(:mime, :string, null: false)
      add(:filesize, :integer, null: false)
      add(:hash, :string, null: false)
      add(:filename, :string, null: false)
      add(:extension, :string, null: false)
      add(:title, :string, default: "", null: false)
      add(:alt, :string, default: "", null: false)
      add(:subtext, :string, default: "", null: false)
      add(:copyright, :string, default: "", null: false)
    end
  end

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [add_content_field: 0, add_media_fields: 0]
    end
  end
end