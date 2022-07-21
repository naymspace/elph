defmodule Elph.Contents.MediaContent do
  @moduledoc """
  This module provides macros and functions to enrich content types with media functionality.
  Right now uploading only handles elph media types. This has to be made configurable.
  """

  @callback create_changeset(term, term) :: term
  @callback create_thumbnails(term) :: term
  @callback convert_media_in_background_tasks(term) :: term

  defmacro media_fields do
    quote do
      field :mime, :string
      field :filesize, :integer
      field :hash, :string
      field :filename, :string
      field :extension, :string
      field :title, :string
      field :alt, :string, default: ""
      field :subtext, :string, default: ""
      field :copyright, :string, default: ""
    end
  end

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [media_fields: 0, delete_from_disk: 1]
      @behaviour unquote(__MODULE__)

      import Ecto.Changeset

      def create_changeset(content, attrs) do
        content
        |> cast(attrs, [:mime, :filesize, :hash, :filename, :extension, :title])
        |> validate_required([:mime, :filesize, :hash, :filename, :extension, :title])
      end

      def create_thumbnails(changeset) do
        changeset
      end

      def convert_media_in_background_tasks(_) do
        []
      end

      def after_delete_callback(content) do
        delete_from_disk(%{hash: content.hash})
      end

      defoverridable create_changeset: 2,
                     convert_media_in_background_tasks: 1,
                     create_thumbnails: 1,
                     after_delete_callback: 1
    end
  end

  defp upload_dir do
    Application.get_env(:elph, :upload_dir)
  end

  def delete_from_disk(%{hash: hash}) do
    File.rm_rf([upload_dir(), hash])
  end

  @doc """
  Returns the path for uploaded media
  """
  def build_default_file_path(hash, extension) do
    build_file_path(hash, "original" <> extension)
  end

  @doc """
  Returns the path for a named file in the directory of an uploaded media
  """

  def build_file_path(hash, filename) do
    Path.join([upload_dir(), hash, filename])
  end
end
