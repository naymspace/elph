defmodule Elph.MediaProcessing do
  @moduledoc """
  The Media context.
  Holds functions for automated editing of media files on the disk.
  This wraps ImageMagick and ffmpeg into easy to access standardized
  function calls.
  """

  import FFmpex
  use FFmpex.Options

  @thumbnail_max_height 240
  @thumbnail_max_width 240

  def create_thumbnail_from_image(path, output_path) do
    FFmpex.new_command()
    |> add_global_option(option_y())
    |> add_input_file(path)
    |> add_output_file(output_path)
    |> add_file_option(
      option_filter(
        "scale=w=#{@thumbnail_max_width}:h=#{@thumbnail_max_height}:force_original_aspect_ratio=decrease"
      )
    )
    |> add_file_option(option_frames(1))
    |> execute()
  end

  def create_poster_from_video(path, output_path) do
    FFmpex.new_command()
    |> add_global_option(option_y())
    |> add_input_file(path)
    |> add_output_file(output_path)
    |> add_file_option(option_filter("thumbnail"))
    |> add_file_option(option_frames(1))
    |> execute()
  end

  def create_default(path, output_path) do
    FFmpex.new_command()
    |> add_global_option(option_y())
    |> add_input_file(path)
    |> add_output_file(output_path)
    |> execute()
  end

  def enqueue_background_conversion(fun) do
    GenServer.cast(Elph.MediaProcessing.BackgroundConverter, {:enqueue, fun})
  end

  @doc """
  Returns the hash of the file as base64. By default it's a full :sha with length 40.
  You can change the :hash or the :length via opts
  """
  def get_file_hash(path, opts \\ []) do
    path
    |> File.stream!([], 2048)
    |> Enum.reduce(
      :crypto.hash_init(Keyword.get(opts, :hash, :sha)),
      fn line, acc -> :crypto.hash_update(acc, line) end
    )
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.slice(0, Keyword.get(opts, :length, 40))
  end

  def get_magic_number_mime(path) do
    path
    |> FileInfo.get_info()
    |> Map.fetch!(path)
    |> (&(&1.type <> "/" <> &1.subtype)).()
    |> normalize_mime()
  rescue
    _ -> ""
  end

  def get_extension_mime(extension) do
    MIME.from_path(extension)
  end

  defp normalize_mime("video/x-m4v"), do: "video/mp4"
  defp normalize_mime(other), do: other

  def get_media_type_for_mime(mime) do
    case mime do
      "image/gif" -> :image
      "image/jpeg" -> :image
      "image/png" -> :image
      "audio/mpeg" -> :audio
      "audio/x-wav" -> :audio
      "video/mp4" -> :video
      "video/quicktime" -> :video
      _ -> :unknown
    end
  end
end
