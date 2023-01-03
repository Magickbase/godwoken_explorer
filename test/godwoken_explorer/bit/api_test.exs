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
end
