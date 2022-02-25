defmodule GodwokenExplorer.Repo.Migrations.AlterSmartContracts do
  use Ecto.Migration

  def change do
    alter table("smart_contracts") do
      add :constructor_arguments, :bytea, null: false
      add :deplayment_tx_hash, :bytea, null: false
      add :compiler_version, :string, null: false
      add :compiler_file_format, :text, null: false
      add :other_info, :text, null: false
    end
  end
end
