defmodule GodwokenExplorer.Repo.Migrations.AlterTransactionWithMethodIdNameIndex do
  use Ecto.Migration

  def change do
    create_if_not_exists(index(:transactions, [:method_id]))
    create_if_not_exists(index(:transactions, [:method_name]))
  end
end
