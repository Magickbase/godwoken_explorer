defmodule Mix.Tasks.UpdateSourcifyMetadata do
  @moduledoc "Printed when the user requests `mix help check_invalid_token_transfer`"

  @shortdoc " `mix update_sourcify_metadata`"

  alias GodwokenExplorer.SmartContract
  alias GodwokenExplorer.Account
  alias GodwokenExplorer.Graphql.Sourcify
  alias GodwokenExplorer.Repo

  import Ecto.Query

  use Mix.Task

  # @chunk_size 100

  @impl Mix.Task
  def run(_args) do
    do_perform()
  end

  def do_perform() do
    q =
      from(s in SmartContract,
        where: not is_nil(s.contract_source_code) and is_nil(s.sourcify_metadata),
        join: a in Account,
        on: a.id == s.account_id,
        where: a.type == :polyjuice_contract,
        select: a.eth_address
      )

    need_process_addresses = Repo.all(q)
    IO.inspect("need_process: #{length(need_process_addresses)}")

    Enum.reduce(need_process_addresses, 1, fn eth_address, acc ->
      IO.inspect("start to process #{acc}")

      Sourcify.verify_and_update_from_sourcify(eth_address)
      |> IO.inspect(label: "verify_and_update_from_sourcify")

      acc + 1
    end)
  end
end
