defmodule GodwokenExplorer.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :hash, :bytea, null: false, primary_key: true
      add :block_hash, :bytea, null: false
      add :block_number, :bigint, null: false
      add :type, :string
      add :from_account_id, :integer, null: false
      add :to_account_id, :integer, null: false
      add :nonce, :integer, null: false
      add :args, :bytea, null: false
      add :status, :string, null: false

      timestamps()
    end

    create(index(:transactions, :block_hash))
  end
end
