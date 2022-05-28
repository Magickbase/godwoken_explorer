defmodule GodwokenExplorer.Repo.Migrations.CreateAccountCurrentBridgedUDTBalance do
  use Ecto.Migration

  def change do
    create table(:account_current_bridged_udt_balances) do
      add :address_hash, :bytea, null: false
      add :account_id, :integer
      add :udt_script_hash, :bytea, null: false
      add :udt_id, :bigint, null: false
      add :value, :decimal, null: false
      add :value_fetched_at, :utc_datetime_usec
      add :layer1_block_number, :bigint, null: false

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(
      unique_index(
        :account_current_bridged_udt_balances,
        ~w(address_hash udt_script_hash)a
      )
    )
  end
end
