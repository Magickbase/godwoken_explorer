defmodule GodwokenExplorer.Repo.Migrations.AddNativeTransferAddressToPolyjuice do
  use Ecto.Migration

  def change do
    alter table(:polyjuices) do
      add :native_transfer_address_hash, :bytea
    end
  end
end
