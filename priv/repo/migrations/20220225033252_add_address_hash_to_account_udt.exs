defmodule GodwokenExplorer.Repo.Migrations.AddAddressHashToAccountUDT do
  use Ecto.Migration

  def change do
    alter table(:account_udts) do
      add :address_hash, :bytea
      add :token_contract_address_hash, :bytea
    end

    create(index(:account_udts, [:address_hash, :token_contract_address_hash], unique: true))
  end
end
