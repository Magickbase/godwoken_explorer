defmodule GodwokenExplorer.Repo.Migrations.UpdateBlockHashNullToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      modify :block_hash, :bytea, null: true
      modify :block_number, :bigint, null: true
    end
  end
end
