defmodule Elph.Repo.Migrations.ChangeExistingAccordionContents do
  use Ecto.Migration
  use Elph.Migration

  # The name of the type has been changed from `accordion` to `accordion_row`. `list` has stayed as it was.
  def change do
    execute(
      "UPDATE contents SET type='accordion_row' WHERE type='accordion'",
      "UPDATE contents SET type='accordion' WHERE type='accordion_row'"
    )
  end
end
