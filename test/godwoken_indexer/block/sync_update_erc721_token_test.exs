defmodule GodwokenIndexer.Block.SyncUpdateERC721Token do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.{TokenTransfer, ERC721Token, Repo}

  setup do
    {:ok, erc721_token_contract_address_hash} =
      GodwokenExplorer.Chain.Hash.Address.cast("0x721c930c2825a960a50ba4ab005e8264488b64a0")

    for _ <- 1..2 do
      _erc721_token_transfer =
        insert(:token_transfer_erc721_inserted,
          token_contract_address_hash: erc721_token_contract_address_hash
        )
    end

    %{
      erc721_token_contract_address_hash: erc721_token_contract_address_hash
    }
  end

  test "Sync Update: import ERC721 tokens from token transfer", %{
    erc721_token_contract_address_hash: _erc721_token_contract_address_hash
  } do
    q = from(t in TokenTransfer)

    tt =
      Repo.all(q)
      |> Enum.map(
        &%{
          from_address_hash: &1.from_address_hash |> to_string,
          to_address_hash: &1.to_address_hash |> to_string,
          token_contract_address_hash: &1.token_contract_address_hash |> to_string,
          token_id: &1.token_id,
          token_type: :erc721,
          block_number: &1.block_number,
          log_index: &1.log_index
        }
      )

    GodwokenIndexer.Block.SyncWorker.update_erc721_token(tt)
    r = from(et in ERC721Token, order_by: [desc: :block_number]) |> Repo.all()
    assert length(r) == 2
  end
end
