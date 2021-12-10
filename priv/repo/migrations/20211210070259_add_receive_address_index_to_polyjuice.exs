defmodule GodwokenExplorer.Repo.Migrations.AddReceiveAddressIndexToPolyjuice do
  use Ecto.Migration

  def change do
    create index(:polyjuice, :receive_address)
  end
end
