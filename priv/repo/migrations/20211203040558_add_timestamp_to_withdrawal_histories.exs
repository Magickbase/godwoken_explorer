defmodule GodwokenExplorer.Repo.Migrations.AddTimestampToWithdrawalHistories do
  use Ecto.Migration

  def change do
    alter table(:withdrawal_histories) do
      add :udt_id, :integer
      add :amount, :decimal
      add :timestamp, :timestamp
      add :state, :string, default: "pending"
    end

    alter table(:deposit_histories) do
      add :timestamp, :timestamp
    end
  end
end
