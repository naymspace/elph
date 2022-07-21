defmodule Elph.Repo.Migrations.CreateImageContents do
  use Ecto.Migration
  use Elph.Migration

  def change do
    create table(:image_contents, primary_key: false) do
      add_media_fields()
      add_content_field()
      add(:thumbnail, :string)
    end
  end
end
