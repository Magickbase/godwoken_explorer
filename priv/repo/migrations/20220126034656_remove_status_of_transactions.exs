defmodule GodwokenExplorer.Repo.Migrations.RemoveStatusOfTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      remove :status
    end
  end
end
