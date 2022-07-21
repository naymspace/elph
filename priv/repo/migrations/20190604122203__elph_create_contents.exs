defmodule Elph.Repo.Migrations.CreateContents do
  use Ecto.Migration

  def change do
    create table(:contents) do
      add(:name, :string, default: "")
      add(:shared, :boolean, default: false)
      add(:type, :string)
      timestamps()
    end

    create table(:content_tree_paths, primary_key: false) do
      add(
        :ancestor_id,
        references(:contents, on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      add(
        :descendant_id,
        references(:contents, on_delete: :delete_all),
        null: false,
        primary_key: true
      )

      add(:order, :integer)
    end

    create(index(:content_tree_paths, [:ancestor_id]))
    create(index(:content_tree_paths, [:descendant_id]))
  end
end
