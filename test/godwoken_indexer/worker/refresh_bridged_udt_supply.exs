defmodule GodwokenIndexer.Worker.RefreshBridgedUDTSupplyTest do
  use GodwokenExplorer.DataCase

  import Mock
  import GodwokenExplorer.Factory

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Token.MetadataRetriever
  alias Decimal, as: D

  setup do
    u = insert(:ckb_udt)
    udt = insert(:ckb_native_udt)

    %{udt: udt, u: u}
  end

  test "update token total supply", %{udt: udt, u: u} do
    with_mock MetadataRetriever,
      get_total_supply_of: fn _address ->
        %{supply: 1000}
      end do
      GodwokenIndexer.Worker.RefreshBridgedUDTSupply.perform(%Oban.Job{
        args: %{"udt_id" => u.id}
      })

      new_udt = Repo.reload!(udt)
      new_u = Repo.reload!(u)

      assert D.compare(new_udt.supply, D.new(1000))
      assert D.compare(new_u.supply, D.new(1000))
    end
  end
end
