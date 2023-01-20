defmodule GodwokenExplorer.Bit.APITest do
  use GodwokenExplorer.DataCase
  use ExUnit.Case, async: false

  import GodwokenExplorer.Factory
  import Mock

  setup do
    user = insert(:user)
    %{user: user}
  end

  test "account hash alias", %{user: user} do
    with_mock HTTPoison,
      post: fn _url, _request, _options ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body:
             "{\"errno\":0,\"errmsg\":\"\",\"data\":{\"account\":\"zmcnotafraid.bit\",\"account_alias\":\"test.bit\"}}"
         }}
      end do
      assert GodwokenExplorer.Bit.API.fetch_reverse_record_info(user.eth_address) ==
               {:ok, "test.bit"}
    end
  end

  test "account on lock", %{user: user} do
    with_mock HTTPoison,
      post: fn _url, _request, _options ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "{\"errno\":20008,\"errmsg\":\"account on lock\",\"data\":null}"
         }}
      end do
      assert GodwokenExplorer.Bit.API.fetch_reverse_record_info(user.eth_address) ==
               {:error, nil}
    end
  end

  test "batch fetch addresses by aliases", %{user: _user} do
    {:ok, data} =
      GodwokenExplorer.Bit.API.batch_fetch_addresses_by_aliases([
        "freder.bit"
      ])

    assert match?([%{bit_alias: "freder.bit"} | _], data)
  end

  test "batch fetch aliases by addresses", %{user: _user} do
    address = "0xcc0af0af911dd40853b8c8dfee90b32f8d1ecad6"

    {:ok, bit_alias} = GodwokenExplorer.Bit.API.fetch_reverse_record_info(address)

    {:ok, data} =
      GodwokenExplorer.Bit.API.batch_fetch_aliases_by_addresses([
        address
      ])

    assert match?([%{bit_alias: ^bit_alias} | _], data)
  end
end
