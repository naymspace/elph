defmodule Elph.Repo.Migrations.CreateVideoContents do
  use Ecto.Migration
  use Elph.Migration

  def change do
    create table(:video_contents, primary_key: false) do
      add_media_fields()
      add_content_field()
      add(:thumbnail, :string)
      add(:poster, :string)
      add(:mp4, :string)
      add(:mp4_conversion, :boolean)
    end
  end
end
