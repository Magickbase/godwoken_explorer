defmodule GodwokenExplorer.Repo.Migrations.AddReceiveEthAddressToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuice) do
      add :receive_eth_address, :bytea
    end

    create index(:polyjuice, :receive_eth_address)
    drop index(:polyjuice, :receive_address)
  end
end
