defmodule GodwokenExplorer.Repo.Migrations.AddTransactionIndexToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuice) do
      add :created_contract_address_hash, :bytea
      add :index, :integer
    end
  end
end
