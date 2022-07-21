defmodule Elph.Contents.ContentType do
  @moduledoc """
  This module provides macros to help with creation of custom content types.

  Start with a schema freshly created by
  `mix phx.gen.schema Contents.Types.Markdown markdown_contents markdown:text`

  Now change some stuff in the `<YourApp>.Contents.Types.Markdown` module.
  - Add `use Ecto.Contents.ContentType` below `use Ecto.Schema`.
  - Change `schema "markdown_contents" do` to `content_schema "markdown_contents" do`.
  - Remove the `timestamps()` call in your schema as Elph already manages timestamps.
  - Write your `changeset` as you would usually and only care about your own stuff. Don't embed or cast the content. This is already handled.
    - Care! The function has to be called `changeset` so it can be called by Elph
  """

  @callback changeset(term, term) :: term
  @callback after_delete_callback(term) :: term
  @callback preloads(term) :: term
  @callback content_preloads(term) :: term

  defmacro content_id do
    quote do
      belongs_to(:content, Elph.Contents.Content,
        primary_key: true,
        foreign_key: :id,
        source: :content_id
      )
    end
  end

  defmacro content_schema(name, do: list) do
    quote do
      @primary_key false
      schema unquote(name) do
        unquote(__MODULE__).content_id()
        field :children, {:array, :map}, virtual: true
        field :name, :string, virtual: true
        field :shared, :boolean, virtual: true
        field :type, :string, virtual: true

        unquote(list)
      end
    end
  end

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [content_schema: 2]
      @behaviour unquote(__MODULE__)

      def after_delete_callback(_) do
        :ok
      end

      def preloads(_) do
        []
      end

      def content_preloads(_) do
        []
      end

      defoverridable after_delete_callback: 1, preloads: 1, content_preloads: 1
    end
  end
end
