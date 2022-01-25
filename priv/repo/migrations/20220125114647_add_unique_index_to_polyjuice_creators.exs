defmodule GodwokenExplorer.Repo.Migrations.AddUniqueIndexToPolyjuiceCreators do
  use Ecto.Migration

  def change do
    create(index(:polyjuice_creators, [:tx_hash], unique: true))
  end
end
