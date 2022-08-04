defmodule GodwokenIndexer.Fetcher.TotalSupplyOnDemandTest do
  use GodwokenExplorerWeb.ConnCase

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
    with_mock MetadataRetriever, get_total_supply_of: fn _address -> %{supply: 10} end do
      GodwokenIndexer.Fetcher.TotalSupplyOnDemand.fetch(to_string(udt.contract_address_hash))
      Process.sleep(1000)

      new_udt = Repo.reload!(udt)
      assert D.compare(new_udt.supply, D.new(10))
    end
  end
end
