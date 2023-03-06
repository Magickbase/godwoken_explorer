defmodule GodwokenExplorer.Repo.Migrations.AlterErc721Tokens do
  use Ecto.Migration

  def change do
    create(index(:erc721_tokens, ~w(address_hash)a))
  end
end
