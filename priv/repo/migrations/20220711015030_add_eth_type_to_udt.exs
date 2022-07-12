defmodule GodwokenExplorer.Repo.Migrations.AddEthTypeToUDT do
  use Ecto.Migration

  def change do
    alter table(:udts) do
      add :eth_type, :string
      add :contract_address_hash, :bytea
    end
  end
end
