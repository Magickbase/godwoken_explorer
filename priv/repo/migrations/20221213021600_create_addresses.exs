defmodule GodwokenExplorer.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses, primary_key: false) do
      add :eth_address, :bytea, null: false, primary_key: true
      add :token_transfer_count, :integer
      add :bit_alias, :string

      timestamps()
    end
  end
end
