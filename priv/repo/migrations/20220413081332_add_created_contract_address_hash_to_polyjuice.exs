defmodule GodwokenExplorer.Repo.Migrations.AddCreatedContractAddressHashToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuice) do
      add :created_contract_address_hash, :bytea
    end
  end
end
