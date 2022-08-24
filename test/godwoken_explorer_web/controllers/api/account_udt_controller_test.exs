defmodule GodwokenExplorerWeb.API.AccountUDTControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.Repo

  setup do
    ckb_native = insert(:ckb_native_udt)
    insert(:ckb_contract_account, eth_address: ckb_native.contract_address_hash)
    insert(:ckb_udt, bridge_account_id: ckb_native.id)
    ckb = insert(:ckb_account)
    user1 = insert(:user)
    user2 = insert(:user)

    udt_balance =
      insert(:current_udt_balance,
        address_hash: user1.eth_address,
        token_contract_address_hash: ckb_native.contract_address_hash,
        value: 1
      )

    bridged_udt_balance =
      insert(:current_bridged_udt_balance,
        address_hash: user2.eth_address,
        udt_script_hash: ckb.script_hash,
        value: 10
      )

    GodwokenExplorer.Account.CurrentBridgedUDTBalance.changeset(bridged_udt_balance, %{
      updated_at: bridged_udt_balance.updated_at |> DateTime.add(10, :second)
    })
    |> Repo.update()

    %{ckb_native: ckb_native, udt_balance: udt_balance, bridged_udt_balance: bridged_udt_balance}
  end

  describe "index" do
    test "return ckb_native holder list", %{
      conn: conn,
      ckb_native: ckb_native,
      udt_balance: udt_balance,
      bridged_udt_balance: bridged_udt_balance
    } do
      conn =
        get(
          conn,
          Routes.account_udt_path(conn, :index, udt_id: ckb_native.id)
        )

      assert json_response(conn, 200) == %{
               "page" => 1,
               "results" => [
                 %{
                   "balance" =>
                     bridged_udt_balance.value
                     |> Decimal.div(Integer.pow(10, 18))
                     |> Decimal.to_string(:normal),
                   "eth_address" => bridged_udt_balance.address_hash |> to_string(),
                   "percentage" => "0.00",
                   "tx_count" => 0
                 },
                 %{
                   "balance" =>
                     udt_balance.value
                     |> Decimal.div(Integer.pow(10, 18))
                     |> Decimal.to_string(:normal),
                   "eth_address" => udt_balance.address_hash |> to_string(),
                   "percentage" => "0.00",
                   "tx_count" => 0
                 }
               ],
               "total_count" => 2
             }
    end
  end
end
