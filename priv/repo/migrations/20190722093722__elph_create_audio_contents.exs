defmodule Elph.Repo.Migrations.CreateAudioContents do
  use Ecto.Migration
  use Elph.Migration

  def change do
    create table(:audio_contents, primary_key: false) do
      add_media_fields()
      add_content_field()
      add(:mp3, :string)
      add(:mp3_conversion, :boolean)

      add(
        :transcript_id,
        references(:list_container_contents, on_delete: :restrict, column: :content_id),
        null: false
      )
    end
  end
end
