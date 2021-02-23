defmodule GodwokenExplorer.Repo.Migrations.CreatePolyjuiceCreators do
  use Ecto.Migration

  def change do
    create table(:polyjuice_creators) do
      add :tx_hash, :bytea
      add :udt_id, :integer
      add :code_hash, :bytea
      add :hash_type, :string

      timestamps()
    end

  end
end
