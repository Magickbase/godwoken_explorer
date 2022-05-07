defmodule GodwokenExplorer.Repo.Migrations.AddCapacityToDepositHistories do
  use Ecto.Migration

  def change do
    alter table("deposit_histories") do
      add :capacity, :decimal
    end

    alter table("withdrawal_histories") do
      add :capacity, :decimal
    end
  end
end
