defmodule GodwokenExplorer.Repo.Migrations.ModifyGasLimitTypeToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuice) do
      modify :gas_limit, :decimal, precision: 100, scale: 0
      modify :gas_used, :decimal, precision: 100, scale: 0
    end
  end
end
