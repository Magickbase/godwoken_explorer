defmodule GodwokenExplorer.Repo.Migrations.CreateAccountCurrentUDTBalance do
  use Ecto.Migration

  def change do
    create table(:account_current_udt_balances) do
      add :address_hash, :bytea, null: false
      add :token_contract_address_hash, :bytea, null: false
      add :udt_id, :integer
      add :account_id, :integer
      add :value, :decimal, null: false
      add :value_fetched_at, :utc_datetime_usec
      add :block_number, :bigint, null: false

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(
      unique_index(:account_current_udt_balances, ~w(address_hash token_contract_address_hash)a)
    )
  end
end
