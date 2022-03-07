defmodule GodwokenExplorer.Repo.Migrations.DropUdtTransfers do
  use Ecto.Migration

  def change do
    drop table("udt_transfers")
  end
end
