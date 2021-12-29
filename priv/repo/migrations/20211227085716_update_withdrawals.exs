defmodule GodwokenExplorer.Repo.Migrations.UpdateWithdrawals do
  use Ecto.Migration

  def change do
    rename table("withdrawals"), :tx_hash, to: :block_hash
    alter table("withdrawals") do
      add :nonce, :integer
      add :block_number, :integer
    end
    rename table("withdrawals"), to: table("withdrawal_requests")
  end
end
