defmodule Mix.Tasks.UpdateErc721Token do
  @moduledoc "Printed when the user requests `mix help update_erc721_token`"

  @shortdoc "running `mix update_erc721_token` to updating erc721 tokens"

  alias GodwokenExplorer.Account.UDTBalance
  alias GodwokenExplorer.TokenTransfer
  alias GodwokenExplorer.Repo

  alias GodwokenExplorer.ERC721Token
  alias GodwokenExplorer.Chain.{Import}
  alias GodwokenExplorer.UDT
  import Ecto.Query

  import GodwokenRPC.Util,
    only: [
      import_utc_timestamps: 0
    ]

  use Mix.Task

  require Logger

  # @chunk_size 100

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    update_newest_erc721_token_info()
  end

  def update_newest_erc721_token_info() do
    zero = UDTBalance.minted_burn_address_hash()

    need_update_tokens =
      from(t in TokenTransfer,
        join: u in UDT,
        on:
          u.contract_address_hash == t.token_contract_address_hash and u.eth_type == :erc721 and
            not is_nil(t.token_id),
        where: t.to_address_hash != ^zero,
        order_by: [asc: t.token_contract_address_hash, asc: t.token_id, desc: t.block_number],
        distinct: [t.token_contract_address_hash, t.token_id],
        select: %{
          token_contract_address_hash: t.token_contract_address_hash,
          token_id: t.token_id,
          address_hash: t.to_address_hash,
          block_number: t.block_number
        }
      )
      |> Repo.all()

    IO.inspect(length(need_update_tokens), label: "need process jobs:")
    chunk_lx = need_update_tokens |> Enum.chunk_every(500)

    Enum.reduce(chunk_lx, 0, fn e, acc ->
      Import.insert_changes_list(e,
        for: ERC721Token,
        timestamps: import_utc_timestamps(),
        on_conflict: :replace_all,
        conflict_target: {:unsafe_fragment, ~s[ (token_contract_address_hash, token_id)  ]}
      )

      IO.inspect(acc, label: "processed jobs:")
      acc + length(e)
    end)
  end
end
