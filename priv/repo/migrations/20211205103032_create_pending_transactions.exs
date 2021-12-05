defmodule GodwokenExplorer.Repo.Migrations.CreatePendingTransactions do
  use Ecto.Migration

  def change do
    create table(:pending_transactions, primary_key: false) do
      add :hash, :bytea, null: false, primary_key: true
      add :from_account_id, :integer
      add :to_account_id, :integer
      add :nonce, :integer
      add :args, :bytea
      add :type, :string
      add :parsed_args, :jsonb

      timestamps()
    end

  end
end
