defmodule GodwokenExplorer.Repo.Migrations.AddBlockNumberIndexToTokenTransfers do
  use Ecto.Migration

  def change do
    create(index(:token_transfers, :block_number))
  end
end
