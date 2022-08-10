defmodule GodwokenExplorerWeb.API.SnapshotControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  describe "export" do
    setup do
      udt = insert(:native_udt)
      a_user = insert(:user)
      b_user = insert(:user)

      _a_first_record =
        insert(:udt_balance,
          token_contract_address_hash: udt.contract_address_hash,
          address_hash: a_user.eth_address,
          block_number: 1
        )

      a_last_record =
        insert(:udt_balance,
          token_contract_address_hash: udt.contract_address_hash,
          address_hash: a_user.eth_address,
          block_number: 10
        )

      b_first_record =
        insert(:udt_balance,
          token_contract_address_hash: udt.contract_address_hash,
          address_hash: b_user.eth_address,
          block_number: 1
        )

      %{a_last_record: a_last_record, b_first_record: b_first_record, udt: udt}
    end

    test "when tx have no erc20 records", %{
      conn: conn,
      a_last_record: a_last_record,
      b_first_record: b_first_record,
      udt: udt
    } do
      conn =
        get(
          conn,
          Routes.snapshot_path(conn, :index,
            start_block_number: 1,
            end_block_number: 10,
            token_contract_address_hash: to_string(udt.contract_address_hash)
          )
        )

      assert conn.resp_body |> String.split("\r\n") |> Enum.drop(1) == [
               "#{a_last_record.address_hash |> to_string},#{a_last_record.value}",
               "#{b_first_record.address_hash |> to_string},#{b_first_record.value}",
               ""
             ]
    end
  end
end
