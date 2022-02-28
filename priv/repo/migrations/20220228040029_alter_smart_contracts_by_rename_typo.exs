defmodule GodwokenExplorer.Repo.Migrations.AlterSmartContractsByRenameTypo do
  use Ecto.Migration

  def change do
    alter table("smart_contracts") do
      remove_if_exists :deplayment_tx_hash, :bytea
      add_if_not_exists :deployment_tx_hash, :bytea
    end
  end
end
