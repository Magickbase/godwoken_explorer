defmodule GodwokenIndexer.Worker.GenerateERC20SeriesContractTest do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory

  alias GodwokenIndexer.Worker.GenerateERC20SeriesContract
  alias GodwokenExplorer.{Account, Repo, SmartContract}

  setup do
    sample_erc20 = insert(:polyjuice_contract_account, id: Account.erc20_sample_id())
    insert(:native_udt, id: sample_erc20.id)
    sample_smart_contract = insert(:smart_contract, account: sample_erc20)
    new_erc20 = insert(:polyjuice_contract_account)

    %{
      sample_smart_contract: sample_smart_contract,
      new_erc20: new_erc20
    }
  end

  test "import smart contract", %{
    sample_smart_contract: sample_smart_contract,
    new_erc20: new_erc20
  } do
    GenerateERC20SeriesContract.perform(%Oban.Job{args: %{"account_id" => new_erc20.id}})

    sc = Repo.get_by(SmartContract, account_id: new_erc20.id)
    assert sc.name == "ERC20"
    assert sc.abi == sample_smart_contract.abi
  end
end
