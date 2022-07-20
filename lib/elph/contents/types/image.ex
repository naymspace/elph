defmodule Elph.Contents.Types.Image do
  @moduledoc """
  This module is for saving image-files as contents. The changeset is only for
  updating image-files - that's why there is a requirement for the id.
  Creating a image-file is handled by the Media-Context.
  """
  use Ecto.Schema
  use Elph.Contents.ContentType
  use Elph.Contents.MediaContent

  alias Elph.Contents.MediaContent
  alias Elph.MediaProcessing

  import Ecto.Changeset

  content_schema "image_contents" do
    media_fields()
    field :thumbnail, :string
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
    thumbnail_path = MediaContent.build_file_path(hash, "thumbnail" <> extension)

    case MediaProcessing.create_thumbnail_from_image(path, thumbnail_path) do
      :ok -> put_change(changeset, :thumbnail, "thumbnail" <> extension)
      _ -> add_error(changeset, :thumbnail, "thumbnail could not be created")
    end
  end
end
