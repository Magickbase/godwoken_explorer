defmodule Mix.Tasks.ClearInvalidUdtBalance do
  @moduledoc "Printed when the user requests `mix help clear_invalid_udt_balance`"
  @shortdoc " `mix clear_invalid_udt_balance`"

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Account.UDTBalance
  import Ecto.Query

  use Mix.Task

  # require Logger

  # @chunk_size 100

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    query = from u in UDTBalance, where: is_nil(u.token_type)
    Repo.delete_all(query) |> IO.inspect()
  end
end
