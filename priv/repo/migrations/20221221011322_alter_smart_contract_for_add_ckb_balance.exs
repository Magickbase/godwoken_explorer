defmodule GodwokenExplorer.Repo.Migrations.AlterSmartContractForAddCkbBalance do
  use Ecto.Migration

  def change do
    alter table(:smart_contracts) do
      add :ckb_balance, :decimal
    end
  end
end
