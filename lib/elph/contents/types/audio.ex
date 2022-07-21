defmodule Elph.Contents.Types.Audio do
  @moduledoc """
  This module is for saving audio-files as contents. The changeset is only for
  updating audio-files - that's why there is a requirement for the id.
  Creating a audio-file is handled by the Media-Context.
  """
  use Ecto.Schema
  use Elph.Contents.ContentType
  use Elph.Contents.MediaContent

  alias Elph.Contents
  alias Elph.Contents.MediaContent
  alias Elph.Contents.Types.ListContainer
  alias Elph.MediaProcessing

  import Ecto.Changeset
  import Elph.Contents.Helper.RequiredLinkedContent

  content_schema "audio_contents" do
    media_fields()
    field :mp3, :string
    field :mp3_conversion, :boolean, default: true
    belongs_to(:transcript, ListContainer)
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, [:id, :filename, :title, :alt, :subtext, :copyright])
    # require :id, so this changeset can only be used for updates!
    |> validate_required([:id, :filename])
  end

  def create_changeset(content, attrs) do
    content
    |> cast(attrs, [:mime, :filesize, :hash, :filename, :extension, :title])
    |> validate_required([:mime, :filesize, :hash, :filename, :extension, :title])
    |> create_required_linked_contents()
  end

  def convert_media_in_background_tasks(content) do
    path = MediaContent.build_default_file_path(content.hash, content.extension)
    mp3_path = MediaContent.build_file_path(content.hash, "converted.mp3")

    [
      mp3: fn ->
        with :ok <- MediaProcessing.create_default(path, mp3_path) do
          {:ok, mp3_path}
        end
      end
    ]
  end

  defp create_required_linked_contents(changeset) do
    title = get_field(changeset, :title) || ""

    empty_transcript = %{
      "type" => "list",
      "children" => [],
      "name" => "audio_transcript_" <> title,
      "shared" => true
    }

    changeset
    |> create_required_linked_content(:transcript_id, empty_transcript)
  end

  def after_delete_callback(content) do
    delete_from_disk(%{hash: content.hash})
    Contents.unshare_contents([content.transcript_id])

    :cleanup
  end

  def content_preloads(:index) do
    []
  end

  def content_preloads(:delete) do
    []
  end

  def content_preloads(:show) do
    [:transcript]
  end
end
