defmodule GodwokenIndexer.Worker.UpdateUDTCountInfoTest do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.UDT
  alias GodwokenIndexer.Worker.UpdateUDTCountInfo
  alias GodwokenExplorer.Account.UDTBalance

  setup do
    minted_burn_address_hash = UDTBalance.minted_burn_address_hash()

    erc721_native_udt = insert(:native_udt, eth_type: :erc721)
    _erc721_native_udt2 = insert(:native_udt, eth_type: :erc721)

    user = insert(:user)

    for index <- 1..5 do
      insert(:token_transfer,
        from_address_hash: minted_burn_address_hash,
        to_address_hash: user.eth_address,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: index
      )
    end

    for index <- 3..5 do
      insert(:token_transfer,
        from_address_hash: user.eth_address,
        to_address_hash: minted_burn_address_hash,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: index
      )
    end

    _erc721_token_instance =
      _erc721_cub1 =
      insert(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: 1,
        block_number: 1,
        value: 1,
        token_type: :erc721
      )

    _erc721_cub2 =
      insert(:current_udt_balance,
        address_hash: user.eth_address,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: 2,
        value: 2,
        block_number: 2,
        token_type: :erc721
      )

    for index <- 3..5 do
      insert(:current_udt_balance,
        token_contract_address_hash: erc721_native_udt.contract_address_hash,
        token_id: index,
        value: 1,
        block_number: 3,
        token_type: :erc721
      )
    end

    _erc721_token_instance =
      insert(:token_instance,
        token_id: 5,
        token_contract_address_hash: erc721_native_udt.contract_address_hash
      )

    %{erc721_native_udt: erc721_native_udt}
  end

  test "worker: update udt count info ", %{erc721_native_udt: erc721_native_udt} do
    contract_address_hash = erc721_native_udt.contract_address_hash
    UpdateUDTCountInfo.do_perform([contract_address_hash], [contract_address_hash])

    udt = Repo.get_by(UDT, contract_address_hash: contract_address_hash)
    assert udt.created_count == 5
    assert udt.burnt_count == 3
  end
end
