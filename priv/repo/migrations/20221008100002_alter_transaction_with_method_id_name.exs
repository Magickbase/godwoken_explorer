defmodule GodwokenExplorer.Repo.Migrations.AlterTransactionWithMethodIdName do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :method_id, :bytea
      add :method_name, :string
    end
  end
end
