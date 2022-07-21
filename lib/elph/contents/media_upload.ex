defmodule Elph.Contents.MediaUpload do
  @moduledoc """
  MediaUpload is the abstract representation for files that can be uploaded to the server.
  MediaUploads have to be transformed into concrete content types later on.
  Those types can be found in Elph.Content.Types.* or be defined by the user.
  Right now uploading only handles elph media types. This has to be made configurable.
  """

  alias Elph.Contents.MediaContent
  alias Elph.MediaProcessing

  use Ecto.Schema
  import Ecto.Changeset

  require Logger

  @hash_length 12

  embedded_schema do
    field :name, :string
    field :mime, :string
    field :path, :string

    field :filesize, :integer
    field :type, :string
    field :filename, :string
    field :extension, :string
    field :hash, :string
    field :new_path, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(media, attrs) do
    with %{valid?: true} = changeset <-
           media
           |> cast(attrs, [:path, :name, :mime])
           |> validate_required([:path, :name, :mime])
           |> validate_file_exists(),
         %{valid?: true} = changeset <-
           changeset
           |> add_title_filename_and_extension()
           |> validate_filetype()
           |> add_filesize()
           |> add_new_path()
           |> validate_new_path() do
      changeset
      |> move_file_to_storage()
    end
  end

  def validate_file_exists(changeset) do
    validate_change(changeset, :path, fn _, path ->
      case File.exists?(path) do
        true -> []
        false -> [{:path, "Temporary file does not exist"}]
      end
    end)
  end

  def validate_filetype(changeset) do
    extension = get_field(changeset, :extension)
    path = get_field(changeset, :path)

    fileextension_mime = MediaProcessing.get_extension_mime(extension)

    magic_number_mime = MediaProcessing.get_magic_number_mime(path)

    type =
      if fileextension_mime == magic_number_mime do
        MediaProcessing.get_media_type_for_mime(fileextension_mime)
      else
        name = get_field(changeset, :filename) <> extension

        Logger.warn(
          "Non-Matching MIME-Types for file #{name}: #{fileextension_mime}, #{magic_number_mime}"
        )

        :unknown
      end

    changeset
    |> change(%{type: type, mime: fileextension_mime})
    |> validate_exclusion(:type, [:unknown], message: "File type not allowed")
  end

  def add_filesize(changeset) do
    filesize =
      changeset
      |> get_field(:path)
      |> File.stat!()
      |> Map.get(:size)

    change(changeset, %{filesize: filesize})
  end

  def add_title_filename_and_extension(changeset) do
    name = get_field(changeset, :name)

    extension = Path.extname(name)

    filename =
      name
      |> Path.basename(extension)
      |> String.slice(0, 250 - String.length(extension))
      |> String.replace(~r/[^A-Za-z0-9_-]+/, "_")

    change(changeset, %{title: filename, filename: filename, extension: extension})
  end

  def add_new_path(changeset) do
    path = get_field(changeset, :path)
    extension = get_field(changeset, :extension)

    hash = MediaProcessing.get_file_hash(path, length: @hash_length)

    new_path = MediaContent.build_default_file_path(hash, extension)

    change(changeset, %{hash: hash, new_path: new_path})
  end

  def validate_new_path(changeset) do
    validate_change(changeset, :new_path, fn _, path ->
      case File.exists?(Path.dirname(path)) do
        true -> [{:path, "File already exists"}]
        false -> []
      end
    end)
  end

  def move_file_to_storage(changeset) do
    case changeset.valid? do
      true ->
        path = get_field(changeset, :path)
        new_path = get_field(changeset, :new_path)

        with :ok <- File.mkdir_p!(Path.dirname(new_path)),
             {:ok, _} <- File.copy(path, new_path) do
          changeset
        else
          {:error, reason} ->
            Logger.error("File couldn't be written to storage: #{Atom.to_string(reason)}")
            add_error(changeset, :path, "File couldn't be written to storage")
        end

      false ->
        changeset
    end
  end
end
