defmodule GodwokenExplorer.Repo.Migrations.AlterSmartContracts do
  use Ecto.Migration

  def change do
    alter table("smart_contracts") do
      add_if_not_exists :constructor_arguments, :bytea
      add_if_not_exists :deployment_tx_hash, :bytea
      add_if_not_exists :compiler_version, :string
      add_if_not_exists :compiler_file_format, :text
      add_if_not_exists :other_info, :text
    end
  end
end
