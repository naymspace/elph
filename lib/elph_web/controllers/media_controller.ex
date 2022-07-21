defmodule ElphWeb.MediaController do
  use ElphWeb, :controller

  alias Elph.Contents

  action_fallback Application.get_env(:elph, :fallback_controller, ElphWeb.FallbackController)

  def create(conn, %{"file" => %Plug.Upload{} = upload}) do
    file = %{name: upload.filename, path: upload.path, mime: upload.content_type}

    with {:ok, %{} = content} <- Contents.create_media_content(file) do
      conn
      |> put_view(ElphWeb.ContentView)
      |> render("show.json", content: content)
    end
  end
end
