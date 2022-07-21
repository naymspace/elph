defmodule ElphWeb.Router do
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
