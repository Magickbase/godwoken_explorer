defmodule GodwokenExplorer.Repo.Migrations.AlterSmartContractsNullRequrieField do
  use Ecto.Migration

  def change do
    alter table(:smart_contracts) do
      modify :name, :string, null: true
      modify :contract_source_code, :text, null: true
      modify :abi, :jsonb, null: true
    end
  end
end
