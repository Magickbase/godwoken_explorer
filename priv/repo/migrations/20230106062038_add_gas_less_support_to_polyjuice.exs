defmodule GodwokenExplorer.Repo.Migrations.AddGasLessSupportToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuices) do
      add :call_contract, :bytea, null: true
      add :call_data, :bytea, null: true
      add :call_gas_limit, :decimal, precision: 100, scale: 0, null: true
      add :verification_gas_limit, :decimal, precision: 100, scale: 0, null: true
      add :max_fee_per_gas, :decimal, precision: 100, null: true
      add :max_priority_fee_per_gas, :decimal, precision: 100, null: true
      add :paymaster_and_data, :bytea, null: true
    end
  end
end
