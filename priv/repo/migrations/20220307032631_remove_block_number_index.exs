defmodule GodwokenExplorer.Repo.Migrations.RemoveBlockNumberIndex do
  use Ecto.Migration

  def change do
    drop index(:transactions, :block_number)
  end
end
