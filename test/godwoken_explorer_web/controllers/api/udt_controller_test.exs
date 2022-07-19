defmodule GodwokenExplorerWeb.API.UDTControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    native_udt = insert(:native_udt)

    udt_account =
      insert(:polyjuice_contract_account,
        id: native_udt.id,
        eth_address: native_udt.contract_address_hash
      )

    insert(:ckb_udt, bridge_account_id: native_udt.id)
    insert(:ckb_account)

    %{udt: native_udt, udt_account: udt_account}
  end

  describe "show" do
    test "when id is eth_address", %{conn: conn, udt: udt, udt_account: udt_account} do
      conn =
        get(
          conn,
          Routes.udt_path(conn, :show, to_string(udt_account.eth_address))
        )

      assert json_response(conn, 200) == %{
               "data" => %{
                 "attributes" => %{
                   "decimal" => udt.decimal,
                   "description" => udt.description,
                   "eth_address" => to_string(udt_account.eth_address),
                   "holder_count" => 0,
                   "icon" => udt.icon,
                   "id" => udt.id,
                   "name" => udt.name,
                   "official_site" => udt.official_site,
                   "supply" => udt.supply |> Decimal.to_string(),
                   "symbol" => udt.symbol,
                   "transfer_count" => 0,
                   "type" => to_string(udt.type),
                   "value" => udt.value
                 },
                 "id" => to_string(udt.id),
                 "relationships" => %{},
                 "type" => "udt"
               },
               "included" => []
             }
    end
  end
end
