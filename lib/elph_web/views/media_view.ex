defmodule ElphWeb.MediaView do
  @moduledoc """
  This module contains views and helper functions for rendering of media content types.
  """

  use ElphWeb, :view

  defp url_upload_dir do
    Application.get_env(:elph, :url_upload_dir)
  end

  def render_base(%{} = media) do
    %{
      mime: media.mime,
      filesize: media.filesize,
      url: build_url(media.hash, default_filename(media.extension)),
      filename: media.filename,
      extension: media.extension,
      alt: media.alt,
      subtext: media.subtext,
      copyright: media.copyright
    }
  end

  def render("image.json", %{media: media}) do
    Map.merge(
      render_base(media),
      %{
        thumbnail: build_url(media.hash, media.thumbnail)
      }
    )
  end

  def render("video.json", %{media: media}) do
    Map.merge(
      render_base(media),
      %{
        thumbnail: build_url(media.hash, media.thumbnail),
        poster: build_url(media.hash, media.poster),
        mp4: build_url(media.hash, media.mp4),
        mp4_conversion: media.mp4_conversion
      }
    )
  end

  def render("audio.json", %{media: media, action: :index}) do
    Map.merge(
      render_base(media),
      %{
        mp3: build_url(media.hash, media.mp3),
        mp3_conversion: media.mp3_conversion,
        transcript_id: media.transcript_id
      }
    )
  end

  def render("audio.json", %{media: media, action: :show}) do
    Map.merge(
      render("audio.json", %{media: media, action: :index}),
      %{
        transcript:
          render_one(media.transcript, ElphWeb.ContentView, "content_with_children.json")
      }
    )
  end

  def default_filename(extension) do
    "original" <> extension
  end

  def build_url(_hash, nil) do
    nil
  end

  def build_url(hash, filename) do
    Path.join([url_upload_dir(), hash, filename])
  end
end
