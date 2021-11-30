defmodule GodwokenExplorer.Repo.Migrations.CreateCheckInfos do
  use Ecto.Migration

  def change do
    create table(:check_infos) do
      add :tip_block_number, :integer
      add :block_hash, :string
      add :type, :string

      timestamps()
    end

  end
end
