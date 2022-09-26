defmodule Mix.Tasks.CheckInvalidTokenTransfer do
  @moduledoc "Printed when the user requests `mix help check_invalid_token_transfer`"

  @shortdoc " `mix check_invalid_token_transfer`"

  alias GodwokenExplorer.TokenTransfer
  alias GodwokenExplorer.Repo

  alias GodwokenExplorer.UDT
  import Ecto.Query

  use Mix.Task

  # @chunk_size 100

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    query =
      from(tt in TokenTransfer,
        left_join: u in UDT,
        on: u.contract_address_hash == tt.token_contract_address_hash,
        where: is_nil(u.eth_type),
        distinct: u.contract_address_hash,
        select: u.contract_address_hash
      )

    return = Repo.all(query)
    return = return |> Enum.map(&(&1 |> to_string))
    IO.inspect(return)
    IO.inspect(length(return))
  end
end
