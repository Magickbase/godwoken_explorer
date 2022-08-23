defmodule GodwokenIndexer.Transform.TokenApprovalsTest do
  use GodwokenExplorer.DataCase

  import GodwokenExplorer.Factory

  alias GodwokenIndexer.Transform.TokenApprovals
  alias GodwokenExplorer.{Log, Repo}

  setup do
    erc20_udt = insert(:native_udt)
    erc721_udt = insert(:native_udt, eth_type: :erc721)
    approval_log = insert(:approval_log, %{address_hash: erc20_udt.contract_address_hash})

    approval_all_log =
      insert(:approval_all_log, %{
        address_hash: erc721_udt.contract_address_hash,
        second_topic: approval_log.second_topic
      })

    %{approval_log: approval_log, approval_all_log: approval_all_log}
  end

  test "parse logs", %{approval_log: approval_log, approval_all_log: approval_all_log} do
    logs = Log |> Repo.all()
    token_approvals = TokenApprovals.parse(logs)
    approval = token_approvals |> List.first()
    approval_all = token_approvals |> List.last()

    assert token_approvals |> Enum.count() == 2
    assert approval.type == :approval

    assert approval.token_owner_address_hash ==
             "0x" <> (approval_log.second_topic |> String.slice(-40..-1))

    assert approval_all.type == :approval_all

    assert approval_all.token_owner_address_hash ==
             "0x" <> (approval_all_log.second_topic |> String.slice(-40..-1))
  end
end
