defmodule Elph.Repo.Migrations.CreateListContainerContents do
  use Ecto.Migration
  use Elph.Migration

  def change do
    create table(:list_container_contents, primary_key: false) do
      add_content_field()
    end
  end
end
