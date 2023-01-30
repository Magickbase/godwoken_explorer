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
    with_mock Tesla,
      execute: fn _, _, _ ->
        {:ok,
         %{
           body: %{"data" => %{"account_alias" => "test.bit"}}
         }}
      end do
      assert GodwokenExplorer.Bit.API.fetch_reverse_record_info(user.eth_address) ==
               {:ok, "test.bit"}
    end
  end

  test "account on lock", %{user: user} do
    with_mock Tesla,
      execute: fn _, _, _ ->
        {:ok,
         %{
           body: %{"data" => nil, "errmsg" => "account on lock", "errno" => 20008}
         }}
      end do
      assert match?(
               {:error, _},
               GodwokenExplorer.Bit.API.fetch_reverse_record_info(user.eth_address)
             )
    end
  end

  test "batch fetch addresses by aliases", %{user: _user} do
    {:ok, data} =
      GodwokenExplorer.Bit.API.batch_fetch_addresses_by_aliases([
        "freder.bit",
        "magickbase.bit"
      ])

    assert match?([%{bit_alias: "freder.bit"} | _], data)
  end

  test "batch fetch aliases by addresses", %{user: _user} do
    freder_address = "0xcc0af0af911dd40853b8c8dfee90b32f8d1ecad6"
    hello_address = "0x38401c6364bfd05c45ceefccc3b75e33fa815815"

    {:ok, freder_address_alias} =
      GodwokenExplorer.Bit.API.fetch_reverse_record_info(freder_address)

    {:ok, data} =
      GodwokenExplorer.Bit.API.batch_fetch_aliases_by_addresses([
        freder_address,
        hello_address
      ])

    assert match?([%{bit_alias: ^freder_address_alias} | _], data)
  end
end
