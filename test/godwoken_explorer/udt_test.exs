defmodule GodwokenExplorer.AccountTest do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.UDT

  setup do
    ckb_udt = insert(:ckb_udt)

    %{ckb_udt: ckb_udt}
  end

  test "erc20 udt no minted count", %{
    ckb_udt: ckb_udt
  } do
    assert UDT.minted_count(ckb_udt) == 0
  end
end
