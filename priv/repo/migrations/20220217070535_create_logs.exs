defmodule GodwokenExplorer.Repo.Migrations.CreateLogs do
  use Ecto.Migration

  def change do
    create table(:logs, primary_key: false) do
      add(:transaction_hash, :bytea, null: false, primary_key: true)
      add(:data, :bytea, null: false)
      add(:index, :integer, null: false, primary_key: true)

      add(:first_topic, :string, null: true)
      add(:second_topic, :string, null: true)
      add(:third_topic, :string, null: true)
      add(:fourth_topic, :string, null: true)

      timestamps()

      add(:address_hash, :bytea, null: false)

      add(:block_number, :bigint, null: false)
      add(:block_hash, :bytea, null: false)
      add(:removed, :boolean, default: false)
    end

    create(index(:logs, :address_hash))
    create(index(:logs, :transaction_hash))

    create(index(:logs, :index))
    create(index(:logs, :first_topic))
    create(index(:logs, :second_topic))
    create(index(:logs, :third_topic))
    create(index(:logs, :fourth_topic))
    create(unique_index(:logs, [:transaction_hash, :index]))
  end
end
