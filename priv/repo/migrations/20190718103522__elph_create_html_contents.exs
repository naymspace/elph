defmodule Elph.Repo.Migrations.CreateHtmlContents do
  use Ecto.Migration
  use Elph.Migration

  def change do
    create table(:html_contents, primary_key: false) do
      add(:html, :text, null: false)

      add_content_field()
    end
  end
end
