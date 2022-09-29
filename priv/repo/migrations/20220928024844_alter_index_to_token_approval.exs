defmodule GodwokenExplorer.Repo.Migrations.AlterIndexToTokenApproval do
  use Ecto.Migration

  def change do
    drop(
      unique_index(:token_approvals, [
        :token_owner_address_hash,
        :spender_address_hash,
        :token_contract_address_hash,
        :data,
        :type
      ])
    )

    create(
      unique_index(
        :token_approvals,
        ~w(token_owner_address_hash token_contract_address_hash spender_address_hash)a,
        name: :approval_erc20_index,
        where: "token_type = 'erc20'"
      )
    )

    create(
      unique_index(
        :token_approvals,
        ~w(token_owner_address_hash token_contract_address_hash data)a,
        name: :approval_erc721_index,
        where: "token_type = 'erc721'"
      )
    )

    create(
      unique_index(
        :token_approvals,
        ~w(token_owner_address_hash token_contract_address_hash)a,
        name: :approval_all_index,
        where: "type = 'approval_all'"
      )
    )
  end
end
