defmodule Elph.Repo.Migrations.CreateAccordionContainerContents do
  use Ecto.Migration
  use Elph.Migration

  def change do
    create table(:accordion_container_contents, primary_key: false) do
      add(:default_open, :boolean, default: false)
      add(:title, :string, default: "", null: false)

      add_content_field()
    end
  end
end
