defmodule Elph.Migration do
  @moduledoc """
  This module provides macros to help you with creating easier migrations for your custom
  content types.

  After creating your schema (and its migration) via
  `mix phx.gen.schema Contents.Types.Markdown markdown_contents markdown:text`

  - Add `use Elph.Migration` below `use Ecto.Migration`
  - In the `create table` call add `add_content_field()` and remove the `timestamps()`.
  """
  defmacro add_content_field(alter \\ false) do
    quote do
      add_or_alter(unquote(alter),
        :content_id,
        references(:contents, on_delete: :delete_all),
        null: false,
        primary_key: true
      )
    end
  end

  defmacro add_media_fields(alter \\ false) do
    quote do
      add_or_alter(unquote(alter), :mime, :string, null: false)
      add_or_alter(unquote(alter), :filesize, :integer, null: false)
      add_or_alter(unquote(alter), :hash, :string, null: false)
      add_or_alter(unquote(alter), :filename, :string, null: false)
      add_or_alter(unquote(alter), :extension, :string, null: false)
      add_or_alter(unquote(alter), :title, :string, default: "", null: false)
      add_or_alter(unquote(alter), :alt, :string, default: "", null: false)
      add_or_alter(unquote(alter), :subtext, :string, default: "", null: false)
      add_or_alter(unquote(alter), :copyright, :string, default: "", null: false)
    end
  end

  defmacro add_or_alter(alter, name, type, keywords) do
    add_fn = if alter do
      :add_if_not_exists
      else
      :add
    end

    quote do
      apply(Ecto.Migration, unquote(add_fn),
        [
          unquote(name),
          unquote(type),
          [unquote(keywords)]
        ]
      )
    end
  end

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end
end
