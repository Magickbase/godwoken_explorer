defmodule GodwokenExplorer.Repo.Migrations.AddIsFastWithdrawalToWithdrawalHistory do
  use Ecto.Migration

  def change do
    alter table(:withdrawal_histories) do
      add :is_fast_withdrawal, :boolean, default: false
    end
  end
end
