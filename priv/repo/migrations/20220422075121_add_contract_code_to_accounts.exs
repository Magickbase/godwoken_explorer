defmodule GodwokenExplorer.Repo.Migrations.AddContractCodeToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add(:contract_code, :bytea, null: true)
    end
  end
end
