defmodule GodwokenIndexer.Worker.UpdateSmartContractCKBTest do
  use GodwokenExplorer.DataCase

  # import Mock
  import GodwokenExplorer.Factory

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Graphql.Workers.UpdateSmartContractCKB
  alias GodwokenExplorer.SmartContract

  setup do
    ckb_account = insert(:ckb_account)
    ckb_contract_account = insert(:ckb_contract_account)
    _ = insert(:ckb_udt)
    _ = insert(:ckb_native_udt)
    polyjuice_contract_account = insert!(:polyjuice_contract_account)
    smart_contract = insert!(:smart_contract, account: polyjuice_contract_account)

    for _ <- 1..3 do
      account = insert!(:polyjuice_contract_account)
      _ = insert!(:smart_contract, account: account)
    end

    _cub =
      insert(:current_udt_balance,
        address_hash: smart_contract.account.eth_address,
        token_contract_address_hash: ckb_contract_account.eth_address,
        value: 10000,
        token_type: :erc20
      )

    %{
      ckb_account: ckb_account,
      smart_contract: smart_contract,
      ckb_contract_account: ckb_contract_account,
      polyjuice_contract_account: polyjuice_contract_account
    }
  end

  test "worker: test UpdateSmartContractCKBTest worker", %{
    polyjuice_contract_account: polyjuice_contract_account
  } do
    account_id = polyjuice_contract_account.id
    address = polyjuice_contract_account.eth_address
    addresses = [to_string(address)]

    UpdateSmartContractCKB.perform(%Oban.Job{
      args: %{"addresses" => addresses}
    })

    sc = Repo.get_by(SmartContract, account_id: account_id)

    assert sc.ckb_balance == Decimal.new(10000)
  end

  test "worker: test update_smart_contract_with_ckb_balance", %{
    ckb_account: ckb_account,
    ckb_contract_account: ckb_contract_account,
    polyjuice_contract_account: polyjuice_contract_account
  } do
    account_id = polyjuice_contract_account.id
    address_hash = polyjuice_contract_account.eth_address
    udt_script_hash = ckb_account.script_hash |> to_string()

    params = %{
      address_hash: address_hash,
      udt_script_hash: udt_script_hash,
      value: 1065
    }

    UpdateSmartContractCKB.update_smart_contract_with_ckb_balance([params])
    sc = Repo.get_by(SmartContract, account_id: account_id)
    assert sc.ckb_balance == Decimal.new(1065)

    token_contract_address_hash = ckb_contract_account.eth_address

    params = %{
      address_hash: address_hash,
      token_contract_address_hash: token_contract_address_hash,
      value: 955
    }

    UpdateSmartContractCKB.update_smart_contract_with_ckb_balance([params])
    sc = Repo.get_by(SmartContract, account_id: account_id)
    assert sc.ckb_balance == Decimal.new(955)
  end
end
