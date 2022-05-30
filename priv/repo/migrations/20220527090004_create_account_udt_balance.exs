defmodule GodwokenExplorer.Repo.Migrations.CreateAccountUDTBalance do
  use Ecto.Migration

  def change do
    create table(:account_udt_balances) do
      add :address_hash, :bytea, null: false
      add :token_contract_address_hash, :bytea, null: false
      add :udt_id, :integer
      add :account_id, :integer
      add :block_number, :bigint
      add :value, :decimal, null: true
      add :value_fetched_at, :utc_datetime_usec, null: true

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create(
      unique_index(
        :account_udt_balances,
        ~w(address_hash token_contract_address_hash block_number)a
      )
    )
  end
end
