defmodule GodwokenExplorer.Repo.Migrations.AddGasUsedToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuice) do
      add :gas_used, :integer
    end
  end
end
