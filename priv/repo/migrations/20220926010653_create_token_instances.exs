defmodule GodwokenExplorer.Repo.Migrations.CreateTokenInstances do
  use Ecto.Migration

  def change do
    create table(:token_instances, primary_key: false) do
      # # ERC-721 tokens have IDs
      # # 10^x = 2^256, x ~ 77.064, so 78 decimal digits will store the full 256-bits of a native EVM type
      # add(:token_id, :numeric, precision: 78, scale: 0, null: false, primary_key: true)

      add(:token_id, :decimal, null: false, primary_key: true)

      add(
        :token_contract_address_hash,
        references(:udts, column: :contract_address_hash, type: :bytea),
        null: false,
        primary_key: true
      )

      add(:metadata, :jsonb)

      add(:error, :string)

      timestamps(null: false, type: :utc_datetime_usec)
    end

    create_if_not_exists(index(:token_instances, :error))
  end
end
