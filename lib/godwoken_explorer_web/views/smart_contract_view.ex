defmodule GodwokenExplorer.SmartContractView do
  use JSONAPI.View, type: "smart_contract"

  import Ecto.Query, only: [from: 2]
  import GodwokenRPC.Util, only: [balance_to_view: 2]

  alias GodwokenExplorer.{SmartContract, Repo, UDT, Account}

  def fields do
    [
      :id,
      :registry_address,
      :name,
      :compiler_version,
      :compiler_file_format,
      :deployment_tx_hash,
      :other_info,
      :balance,
      :tx_count
    ]
  end

  def registry_address(smart_contract, _conn) do
    smart_contract.account.eth_address
  end

  def balance(smart_contract, _conn) do
    with udt_id when is_integer(udt_id) <- UDT.ckb_account_id(),
         {:ok, balance} <-
           GodwokenRPC.fetch_balance(smart_contract.account.registry_address, udt_id) do
      balance_to_view(balance, 18)
    else
      _ -> 0
    end
  end

  def tx_count(smart_contract, _conn) do
    case Repo.get(Account, smart_contract.account_id) do
      %Account{transaction_count: transaction_count} -> transaction_count || 0
      nil -> 0
    end
  end

  def list(paging_options) do
    from(
      sc in SmartContract,
      preload: :account,
      where: not is_nil(sc.deployment_tx_hash),
      select: map(sc, ^select_fields())
    )
    |> Repo.paginate(page: paging_options[:page], page_size: paging_options[:page_size])
  end

  def select_fields do
    smart_contract_fields = [
      :id,
      :name,
      :account_id,
      :compiler_version,
      :compiler_file_format,
      :deployment_tx_hash,
      :other_info
    ]

    account_fields = [:eth_address, :registry_address]

    smart_contract_fields ++ [account: account_fields]
  end
end
