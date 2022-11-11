defmodule GodwokenIndexer.Worker.UpdateUDTInfoTest do
  use GodwokenExplorer.DataCase

  import Mock
  import GodwokenExplorer.Factory

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Token.MetadataRetriever
  alias Decimal, as: D

  setup do
    udt = insert(:native_udt)
    %{udt: udt}
  end

  test "update token total supply", %{udt: udt} do
    with_mock MetadataRetriever,
      get_functions_of: fn _address ->
        %{decimal: 18, name: "pCKB", supply: 100, symbol: "pCKB"}
      end do
      GodwokenIndexer.Worker.UpdateUDTInfo.perform(%Oban.Job{
        args: %{"address_hash" => udt.contract_address_hash}
      })

      new_udt = Repo.reload!(udt)

      assert D.compare(new_udt.supply, D.new(10))
      assert new_udt.decimal == 18
      assert new_udt.name == "pCKB"
      assert new_udt.symbol == "pCKB"
    end
  end
end
