defmodule ElphWeb.UploadPlug do
  @moduledoc """
  This module is a covenience-wrapper for the Plug.Static to deliver uploaded files via static route.
  """
  def init(_opts) do
    Plug.Static.init(
      at: Application.get_env(:elph, :url_upload_dir),
      from: Application.get_env(:elph, :upload_dir),
      gzip: false
    )
  end

  def call(conn, opts), do: Plug.Static.call(conn, opts)
end
