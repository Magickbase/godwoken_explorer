defmodule GodwokenExplorer.Repo.Migrations.DropAccountUDTAndRenamePolyjuice do
  use Ecto.Migration

  def change do
    drop table(:account_udts)
    rename table(:polyjuice), to: table(:polyjuices)
  end
end
