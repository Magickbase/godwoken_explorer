defmodule GodwokenExplorer.Repo.Migrations.AddTokenTypeToTokenApproval do
  use Ecto.Migration

  def change do
    alter table(:token_approvals) do
      add :token_type, :string
    end
  end
end
