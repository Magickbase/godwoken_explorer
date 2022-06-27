defmodule GodwokenExplorer.Repo.Migrations.AddHashToWithdrawalRequest do
  use Ecto.Migration

  def change do
    alter table(:withdrawal_requests) do
      add :hash, :bytea
    end
  end
end
