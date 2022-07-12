defmodule GodwokenExplorer.Repo.Migrations.AddUnqiueIndexToUDT do
  use Ecto.Migration

  def change do
    create unique_index(:udts, [:contract_address_hash])
  end
end
