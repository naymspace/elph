defmodule Elph.Repo.Migrations.UpgradeMediaPre07 do
  use Ecto.Migration

  def change do
    alter table("audio_contents") do
      modify(:mime, :string, null: false)
      modify(:filesize, :integer, null: false)
      modify(:hash, :string, null: false)
      modify(:filename, :string, null: false)
      modify(:extension, :string, null: false)
      add(:title, :string, default: "", null: false)
      add(:alt, :string, default: "", null: false)
      add(:subtext, :string, default: "", null: false)
      add(:copyright, :string, default: "", null: false)

      add(
        :transcript_id,
        references(:list_container_contents, on_delete: :restrict, column: :content_id),
        null: false
      )
    end

    alter table("image_contents") do
      modify(:mime, :string, null: false)
      modify(:filesize, :integer, null: false)
      modify(:hash, :string, null: false)
      modify(:filename, :string, null: false)
      modify(:extension, :string, null: false)
      add(:title, :string, default: "", null: false)
      add(:alt, :string, default: "", null: false)
      add(:subtext, :string, default: "", null: false)
      add(:copyright, :string, default: "", null: false)
    end

    alter table("video_contents") do
      modify(:mime, :string, null: false)
      modify(:filesize, :integer, null: false)
      modify(:hash, :string, null: false)
      modify(:filename, :string, null: false)
      modify(:extension, :string, null: false)
      add(:title, :string, default: "", null: false)
      add(:alt, :string, default: "", null: false)
      add(:subtext, :string, default: "", null: false)
      add(:copyright, :string, default: "", null: false)
    end
  end
end
