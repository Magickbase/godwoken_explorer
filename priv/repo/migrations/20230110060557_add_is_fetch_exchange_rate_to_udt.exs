defmodule GodwokenExplorer.Repo.Migrations.AddIsFetchExchangeRateToUdt do
  use Ecto.Migration

  def change do
    alter table(:udts) do
      add :is_fetch_exchange_rate, :boolean, default: false
      remove :value
      remove :price
    end
  end
end
