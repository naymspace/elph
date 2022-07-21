defmodule ElphWeb.ContentController do
  @moduledoc """
  This controller holds the basic functions of elph. Manipulation of contents.
  """
  use ElphWeb, :controller

  alias Elph.Contents

  action_fallback Application.get_env(:elph, :fallback_controller, ElphWeb.FallbackController)

  def types, do: Application.get_env(:elph, :types, Elph.Contents.DefaultTypes)

  def index(conn, params) do
    opts = [
      show_all:
        case params["show_all"] do
          "true" -> true
          _ -> false
        end,
      type:
        if is_binary(params["type"]) do
          params["type"]
          |> String.split(",")
          |> Enum.filter(&types().valid_type?(&1))
        else
          nil
        end,
      page:
        with p when is_binary(p) <- params["page"],
             {n, _} when n > 0 <- Integer.parse(p) do
          n
        else
          _ -> 1
        end,
      page_size:
        with p when is_binary(p) <- params["page_size"],
             {n, _} when n > 0 <- Integer.parse(p) do
          n
        else
          _ -> 0
        end,
      search: params["search"]
    ]

    contents = Contents.list_contents(opts)
    render(conn, "index.json", contents: contents)
  end

  # is create and update. Needs to be called create because its accessed with the create route
  def create(conn, %{"content" => content_params}) do
    with {:ok, %{} = content} <- Contents.persist_content(content_params) do
      conn
      |> render("show.json", content: content)
    end
  end

  def show(conn, %{"id" => id}) do
    content = Contents.get_content!(id)
    render(conn, "show.json", content: content)
  end

  def delete(conn, %{"id" => id}) do
    with :ok <- id |> Contents.get_content!() |> Contents.delete_content() do
      send_resp(conn, :no_content, "")
    end
  end
end
