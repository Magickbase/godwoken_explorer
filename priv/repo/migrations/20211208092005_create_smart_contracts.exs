defmodule GodwokenExplorer.Repo.Migrations.CreateSmartContracts do
  use Ecto.Migration

  def change do
    create table(:smart_contracts) do
      add :name, :string, null: false
      add :contract_source_code, :text, null: false
      add :abi, :jsonb, null: false

      add(:account_id, references(:accounts, column: :id, on_delete: :delete_all, type: :integer), null: false)

      timestamps()
    end
  end
end
