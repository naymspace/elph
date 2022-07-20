defmodule ElphWeb.ContentView do
  @moduledoc """
  This module contains views for the default non-media content types as well as some
  helper functions that take care of content-tree rendering.
  """
  use ElphWeb, :view

  def types, do: Application.get_env(:elph, :types, Elph.Contents.DefaultTypes)

  # Universal content rendering

  def render("index.json", %{contents: {contents, current_page, pages_count}}) do
    %{
      data: render_many(contents, __MODULE__, "content.json"),
      current_page: current_page,
      pages_count: pages_count
    }
  end

  def render("index.json", %{contents: contents, action: action}) do
    %{data: render_many(contents, __MODULE__, "content.json", action: action)}
  end

  def render("index.json", %{contents: contents}) do
    render("index.json", %{contents: contents, action: :index})
  end

  def render("show.json", %{content: content, action: action}) do
    %{
      data: render_one(content, __MODULE__, "content_with_children.json", action: action)
    }
  end

  def render("show.json", %{content: content}) do
    render("show.json", %{content: content, action: :show})
  end

  def render("content.json", %{content: content, action: action}) do
    base = %{
      id: content.id,
      name: content.name,
      shared: content.shared,
      type: content.type
    }

    view = types().get_view(content.type)

    case view do
      nil ->
        base

      _ ->
        Map.merge(
          render_one(content, view, content.type <> ".json", action: action),
          base
        )
    end
  end

  def render("content.json", %{content: content}) do
    render("content.json", %{content: content, action: :index})
  end

  def render("content_with_children.json", %{content: content, action: action}) do
    case Map.get(content, :children) do
      nil ->
        render("content.json", %{content: content, action: action})

      children ->
        Map.merge(
          render("content.json", %{content: content, action: action}),
          %{
            children:
              render_many(children, __MODULE__, "content_with_children.json", action: action)
          }
        )
    end
  end

  def render("content_with_children.json", %{content: content}) do
    render("content_with_children.json", %{content: content, action: :show})
  end

  # Elph non-media content types

  def render("markdown.json", %{content: content, action: action}) do
    %{markdown: content.markdown, op: action}
  end

  def render("accordion_row.json", %{content: content}) do
    %{
      default_open: content.default_open,
      title: content.title
    }
  end

  def render("html.json", %{content: content}) do
    %{html: content.html}
  end
end
