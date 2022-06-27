defmodule GodwokenExplorer.Repo.Migrations.AddUDTScriptHashToDepositHistories do
  use Ecto.Migration

  def change do
    alter table(:deposit_histories) do
      add :udt_script_hash, :bytea
    end
  end
end
