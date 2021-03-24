defmodule GodwokenExplorer.Repo.Migrations.CreateAccountUdts do
  use Ecto.Migration

  def change do
    create table(:account_udts) do
      add :account_id, :integer
      add :udt_id, :integer
      add :balance, :decimal, default: 0

      timestamps()
    end

  end
end
