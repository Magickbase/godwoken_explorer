defmodule GodwokenExplorer.Repo.Migrations.AddTransactionIndexToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuice) do
      add :transaction_index, :integer
    end
  end
end
