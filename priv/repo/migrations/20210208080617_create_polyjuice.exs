defmodule GodwokenExplorer.Repo.Migrations.CreatePolyjuice do
  use Ecto.Migration

  def change do
    create table(:polyjuice) do
      add :tx_hash, :bytea
      add :is_create, :boolean, default: false, null: false
      add :is_static, :boolean, default: false, null: false
      add :gas_limit, :bigint
      add :gas_price, :decimal
      add :value, :decimal
      add :input_size, :integer
      add :input, :bytea

      timestamps()
    end

  end
end
