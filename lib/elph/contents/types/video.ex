defmodule Elph.Contents.Types.Video do
  @moduledoc """
  This module is for saving video-files as contents. The changeset is only for
  updating video-files - that's why there is a requirement for the id.
  Creating a video-file is handled by the Media-Context.
  """
  use Ecto.Schema
  use Elph.Contents.ContentType
  use Elph.Contents.MediaContent

  alias Elph.Contents.MediaContent
  alias Elph.MediaProcessing

  import Ecto.Changeset

  content_schema "video_contents" do
    media_fields()
    field(:thumbnail, :string)
    field(:poster, :string)
    field(:mp4, :string)
    field(:mp4_conversion, :boolean, default: true)
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, [:id, :filename, :title, :alt, :subtext, :copyright])
    # require :id, so this changeset can only be used for updates!
    |> validate_required([:id, :filename])
  end

  def create_thumbnails(changeset) do
    hash = get_field(changeset, :hash)
    extension = get_field(changeset, :extension)

    path = MediaContent.build_default_file_path(hash, extension)
    thumbnail_path = MediaContent.build_file_path(hash, "thumbnail.png")
    poster_path = MediaContent.build_file_path(hash, "poster.png")

    with {:ok, _} <- MediaProcessing.create_poster_from_video(path, poster_path),
         {:ok, _} <- MediaProcessing.create_thumbnail_from_image(poster_path, thumbnail_path) do
      changeset
      |> put_change(:thumbnail, "thumbnail.png")
      |> put_change(:poster, "poster.png")
    else
      _ ->
        add_error(changeset, :thumbnail, "thumbnail could not be created")
    end
  end

  def convert_media_in_background_tasks(content) do
    path = MediaContent.build_default_file_path(content.hash, content.extension)
    mp4_path = MediaContent.build_file_path(content.hash, "converted.mp4")

    [
      mp4: fn ->
        with {:ok, _} <- MediaProcessing.create_default(path, mp4_path) do
          {:ok, mp4_path}
        end
      end
    ]
  end
end
