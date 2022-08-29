defmodule GodwokenExplorer.AccountTest do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.Account

  setup do
    user = insert(:user)
    insert(:polyjuice_contract_account)

    %{user: user}
  end

  test "count" do
    assert Account.count() == 2
  end

  describe "search" do
    test "eth_address", %{user: user} do
      assert Account.search(user.eth_address) == user
    end
  end
end
