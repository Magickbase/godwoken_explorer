defmodule GodwokenExplorer.Repo.Migrations.DropPolyjuiceColumns do
  use Ecto.Migration

  def change do
    alter table(:polyjuice) do
      remove :transfer_count
      remove :receive_eth_address
      remove :receive_address
    end
  end
end
