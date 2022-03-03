defmodule GodwokenExplorer.Repo.Migrations.AddChainIdToWithdrawalRequests do
  use Ecto.Migration

  def change do
    alter table(:withdrawal_requests) do
      add :chain_id, :bigint
      remove :sell_amount
      remove :sell_capacity
      remove :payment_lock_hash
      remove :fee_udt_id
    end
  end
end
