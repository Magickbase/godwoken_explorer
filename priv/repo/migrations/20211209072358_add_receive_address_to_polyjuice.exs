defmodule GodwokenExplorer.Repo.Migrations.AddReceiveAddressToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuice) do
      add :receive_address, :bytea
      add :transfer_count, :decimal
    end
  end
end
