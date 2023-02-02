defmodule GodwokenExplorer.Repo.Migrations.AddImplementationAddressHashToSmartContract do
  use Ecto.Migration

  def change do
    alter table(:smart_contracts) do
      add(:address_hash, :bytea)
      add(:implementation_name, :string, null: true)
      add(:implementation_address_hash, :bytea, null: true)
      add(:implementation_fetched_at, :"timestamp without time zone", null: true)
    end
  end
end
