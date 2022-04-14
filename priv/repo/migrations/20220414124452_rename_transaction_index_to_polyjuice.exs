defmodule GodwokenExplorer.Repo.Migrations.RenameTransactionIndexToPolyjuice do
  use Ecto.Migration

  def change do
    rename table("polyjuice"), :index, to: :transaction_index
  end
end
