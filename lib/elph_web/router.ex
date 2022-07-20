defmodule ElphWeb.Router do
  @moduledoc """
  DEPRECATED

  This Module contains a simple default router where calls from your api can be forwarded to.
  Since basic elph has no authentication yet, this router doesn't also!
  If you want to forward requests to this router, make sure they are authenticated.
  """
  use ElphWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ElphWeb do
    pipe_through :api
    resources "/contents", ContentController, only: [:index, :show, :create, :delete]
    resources "/media", MediaController, only: [:create]
  end
end
