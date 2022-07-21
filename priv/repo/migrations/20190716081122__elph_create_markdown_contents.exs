defmodule Elph.Repo.Migrations.CreateMarkdownContents do
  use Ecto.Migration
  use Elph.Migration

  def change do
    create table(:markdown_contents, primary_key: false) do
      add(:markdown, :text)

      add_content_field()
    end
  end
end
