defmodule Elph.Repo.Migrations.RenameContainerContents do
  use Ecto.Migration
  use Elph.Migration

  def change do
    rename table("accordion_container_contents"), to: table("accordion_row_contents")
    rename table("list_container_contents"), to: table("list_contents")
  end
end
