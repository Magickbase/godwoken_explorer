defmodule GodwokenExplorerWeb.API.UDTControllerTest do
  use GodwokenExplorer, :schema
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.{Account, Repo}

  setup do
    Account.create_or_update_account!(ckb_account_factory())
    Repo.insert(ckb_udt_factory())
    :ok
  end

  describe "show" do
    test "when id is integer", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.account_path(conn, :show, "1")
        )

      assert json_response(conn, 200) ==
               %{
                 "ckb" => "",
                 "eth" => "",
                 "eth_addr" => "0x9e9c54293c3211259de788e97a31b5b3a66cd535",
                 "id" => "1",
                 "sudt" => %{
                   "decimal" => 8,
                   "holders" => 0,
                   "icon" => nil,
                   "name" => "CKB",
                   "script_hash" =>
                     "0x9e9c54293c3211259de788e97a31b5b3a66cd53564f8d39dfabdc8e96cdf5ea4",
                   "supply" => "0",
                   "symbol" => nil,
                   "type_script" => nil
                 },
                 "tx_count" => "0",
                 "type" => "udt"
               }
    end

    test "when id is eth_address", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.account_path(conn, :show, "0x9e9c54293c3211259de788e97a31b5b3a66cd535")
        )

      assert json_response(conn, 200) ==
               %{
                 "ckb" => "",
                 "eth" => "",
                 "eth_addr" => "0x9e9c54293c3211259de788e97a31b5b3a66cd535",
                 "id" => 1,
                 "sudt" => %{
                   "decimal" => 8,
                   "holders" => 0,
                   "icon" => nil,
                   "name" => "CKB",
                   "script_hash" =>
                     "0x9e9c54293c3211259de788e97a31b5b3a66cd53564f8d39dfabdc8e96cdf5ea4",
                   "supply" => "0",
                   "symbol" => nil,
                   "type_script" => nil
                 },
                 "tx_count" => "0",
                 "type" => "udt"
               }
    end
  end
end
