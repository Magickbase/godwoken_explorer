defmodule GodwokenIndexer.Worker.CheckContractUDTTest do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory
  import Mock

  alias GodwokenIndexer.Worker.CheckContractUDT
  alias GodwokenExplorer.{Account, Repo, SmartContract, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever

  setup do
    sample_erc20 = insert(:polyjuice_contract_account, id: Account.erc20_sample_id())
    insert(:native_udt, id: sample_erc20.id)
    sample_smart_contract = insert(:smart_contract, account: sample_erc20)
    new_erc20 = insert(:polyjuice_contract_account, contract_code: sample_erc20.contract_code)

    %{
      sample_smart_contract: sample_smart_contract,
      new_erc20: new_erc20
    }
  end

  test "check contract is erc20", %{
    sample_smart_contract: sample_smart_contract,
    new_erc20: new_erc20
  } do
    with_mock MetadataRetriever,
      get_functions_of: fn _address ->
        %{decimal: 18, name: "ETH", supply: 1_009_100_000_000_000, symbol: "ETH"}
      end do
      CheckContractUDT.perform(%Oban.Job{
        args: %{"address" => new_erc20.eth_address |> to_string()}
      })

      udt = Repo.get_by(UDT, id: new_erc20.id)
      assert udt != nil
      sc = Repo.get_by(SmartContract, account_id: new_erc20.id)
      assert sc.abi == sample_smart_contract.abi
    end
  end

  test "check contract is not udt" do
    assert UDT |> Repo.aggregate(:count) == 1

    CheckContractUDT.perform(%Oban.Job{
      args: %{"address" => "0xc806a37164860913fbff8d013986229724d6c418"}
    })

    assert UDT |> Repo.aggregate(:count) == 1
  end
end
