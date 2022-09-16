defmodule GodwokenExplorer.Repo.Migrations.AlterUdtBalance do
  use Ecto.Migration

  def change do
    alter table(:account_udt_balances) do
      add :token_id, :decimal
      add :token_type, :string
    end

    alter table(:account_current_udt_balances) do
      add :token_id, :decimal
      add :token_type, :string
    end
  end
end
