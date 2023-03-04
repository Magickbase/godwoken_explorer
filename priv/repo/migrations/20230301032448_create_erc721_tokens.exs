defmodule GodwokenExplorer.Repo.Migrations.CreateErc721Tokens do
  use Ecto.Migration

  def change do
    create table(:erc721_tokens, primary_key: false) do
      add :token_contract_address_hash, :bytea, primary_key: true, null: false
      add :token_id, :decimal, primary_key: true, null: false
      add :address_hash, :bytea, null: false
      add :block_number, :bigint, null: false

      timestamps(null: false, type: :utc_datetime)
    end
  end
end
