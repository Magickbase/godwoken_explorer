defmodule GodwokenExplorer.Repo.Migrations.AddProducerAddressToBlocks do
  use Ecto.Migration

  def change do
    alter table(:blocks) do
      remove :aggregator_id
      add :registry_id, :integer
      add :producer_address, :bytea
    end
  end
end
