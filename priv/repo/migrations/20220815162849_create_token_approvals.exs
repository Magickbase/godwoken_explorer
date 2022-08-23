defmodule GodwokenExplorer.Repo.Migrations.CreateTokenApprovals do
  use Ecto.Migration

  def change do
    create table(:token_approvals) do
      add :block_hash, :bytea
      add :block_number, :integer
      add :transaction_hash, :bytea
      add :token_owner_address_hash, :bytea
      add :spender_address_hash, :bytea
      add :token_contract_address_hash, :bytea
      add :data, :decimal, precision: 100, scale: 0
      add :approved, :boolean
      add :type, :string

      timestamps()
    end

    create unique_index(:token_approvals, [
             :token_owner_address_hash,
             :spender_address_hash,
             :token_contract_address_hash,
             :data,
             :type
           ])
  end
end
