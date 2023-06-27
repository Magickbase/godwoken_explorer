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
           body: %{"data" => %{"account" => "test.bit", "account_alias" => "test.bit"}}
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
    with_mock Tesla,
      execute: fn _, _, _ ->
        {:ok,
         %{
           body: %{
             "data" => %{
               "list" => [
                 %{
                   "account" => "freder.bit",
                   "account_id" => "0x4027ebb00204379b84db0714b9e10f73c1434cbc",
                   "err_msg" => "",
                   "records" => [
                     %{
                       "key" => "address.60",
                       "label" => "",
                       "ttl" => "300",
                       "value" => "0xcc0af0af911dd40853b8c8dfee90b32f8d1ecad6"
                     },
                     %{
                       "key" => "profile.avatar",
                       "label" => "",
                       "ttl" => "300",
                       "value" =>
                         "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Flag_of_Argentina.svg/2560px-Flag_of_Argentina.svg.png"
                     },
                     %{
                       "key" => "profile.description",
                       "label" => "",
                       "ttl" => "300",
                       "value" =>
                         "During the epidemic, wear a mask frequently and drink plenty of water to protect yourself and your family."
                     },
                     %{
                       "key" => "profile.github",
                       "label" => "",
                       "ttl" => "300",
                       "value" => "FrederLu"
                     },
                     %{
                       "key" => "profile.discord",
                       "label" => "",
                       "ttl" => "300",
                       "value" => "981133411190177812"
                     }
                   ]
                 },
                 %{
                   "account" => "magickbase.bit",
                   "account_id" => "0x07d765887d5545b7255b22c8cf49607c054c58f8",
                   "err_msg" => "",
                   "records" => [
                     %{
                       "key" => "profile.github",
                       "label" => "",
                       "ttl" => "300",
                       "value" => "Magickbase"
                     },
                     %{
                       "key" => "profile.discord",
                       "label" => "",
                       "ttl" => "300",
                       "value" => "https://discord.gg/N9nZ3JE2Gg"
                     },
                     %{
                       "key" => "profile.avatar",
                       "label" => "",
                       "ttl" => "300",
                       "value" => "https://avatars.githubusercontent.com/u/103997195"
                     },
                     %{
                       "key" => "profile.description",
                       "label" => "",
                       "ttl" => "300",
                       "value" =>
                         "As a comprehensive ecosystem that combines powerful decision-making tools, secure blockchain technology, and robust infrastructure, Magickbase is a valuable resource for anyone looking to take control of their data on Nervos CKB and use it in innovative and transformative ways."
                     },
                     %{
                       "key" => "custom_key.kanban",
                       "label" => "",
                       "ttl" => "300",
                       "value" => "https://github.com/orgs/Magickbase/projects/1/views/2"
                     }
                   ]
                 }
               ]
             },
             "errmsg" => "",
             "errno" => 0
           }
         }}
      end do
      {:ok, data} =
        GodwokenExplorer.Bit.API.batch_fetch_addresses_by_aliases([
          "freder.bit",
          "magickbase.bit"
        ])

      assert match?([%{bit_alias: "freder.bit"} | _], data)
    end
  end

  test "batch fetch aliases by addresses", %{user: _user} do
    with_mock Tesla,
      execute: fn _, _, _ ->
        {:ok,
         %{
           body: %{
             "data" => %{
               "list" => [
                 %{
                   "account" => "freder.bit",
                   "account_alias" => "freder.bit",
                   "err_msg" => ""
                 },
                 %{
                   "account" => "mybit.bit",
                   "account_alias" => "mybit.bit",
                   "err_msg" => ""
                 }
               ]
             }
           }
         }}
      end do
      freder_address = "0xcc0af0af911dd40853b8c8dfee90b32f8d1ecad6"
      hello_address = "0x38401c6364bfd05c45ceefccc3b75e33fa815815"

      {:ok, data} =
        GodwokenExplorer.Bit.API.batch_fetch_aliases_by_addresses([
          freder_address,
          hello_address
        ])

      assert match?([%{bit_alias: "freder.bit"} | _], data)
    end
  end
end
