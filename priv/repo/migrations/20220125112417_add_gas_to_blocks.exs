defmodule GodwokenExplorer.Repo.Migrations.AddGasToBlocks do
  use Ecto.Migration

  def change do
    alter table(:blocks) do
      add :gas_used, :decimal, precision: 100, scale: 0
      add :gas_limit, :decimal, precision: 100, scale: 0
      add :difficulty, :decimal, precision: 50, scale: 0
      add :total_difficulty, :decimal, precision: 50, scale: 0
      add :nonce, :bytea
      add :sha3_uncles, :bytea
      add :state_root, :bytea
      add :extra_data, :bytea
      remove :average_gas_price
      remove :tx_fees
    end

    drop index(:blocks, :hash)
  end
end
