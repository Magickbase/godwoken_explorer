defmodule GodwokenExplorer.SmartContractTest do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory
  import Mock

  alias GodwokenExplorer.{Repo, SmartContract}
  alias GodwokenExplorer.SmartContract.Reader

  setup do
    unknown_sc = insert(:proxy_contract, abi: nil)

    contract_account = insert(:polyjuice_contract_account)
    insert(:smart_contract, account: contract_account, address_hash: contract_account.eth_address)

    proxy_sc =
      insert(:proxy_contract,
        implementation_address_hash: contract_account.eth_address,
        implementation_name: "proxy contract"
      )

    not_bind_sc = insert(:proxy_contract)

    %{
      unknown_sc: unknown_sc,
      proxy_sc: proxy_sc,
      contract_account: contract_account,
      not_bind_sc: not_bind_sc
    }
  end

  describe "get_implementation_address_hash" do
    test "when abi is nil", %{unknown_sc: unknown_sc} do
      assert SmartContract.get_implementation_address_hash(unknown_sc) == {nil, nil}
    end

    test "when implementation info exist", %{
      proxy_sc: proxy_sc,
      contract_account: contract_account
    } do
      assert SmartContract.get_implementation_address_hash(proxy_sc) ==
               {to_string(contract_account.eth_address), "proxy contract"}
    end

    test "bind proxy contract with implenmation_contract", %{
      not_bind_sc: not_bind_sc,
      contract_account: contract_account
    } do
      with_mock Reader,
        query_contract: fn _, _, _, _ ->
          %{"5c60da1b" => {:ok, [to_string(contract_account.eth_address)]}}
        end do
        assert not_bind_sc.implementation_address_hash == nil
        SmartContract.get_implementation_address_hash(not_bind_sc)

        assert Repo.reload(not_bind_sc).implementation_address_hash ==
                 contract_account.eth_address
      end
    end
  end
end
