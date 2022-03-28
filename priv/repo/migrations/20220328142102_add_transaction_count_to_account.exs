defmodule GodwokenExplorer.Repo.Migrations.AddTransactionCountToAccount do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :transaction_count, :integer
      add :token_transfer_count, :integer
    end
  end
end
