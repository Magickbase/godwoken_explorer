defmodule GodwokenRPC.Transactions do
  @moduledoc """
  Transactions format as returned by `GodwokenRPC.Block.ByNumber` module.
  """

  alias GodwokenRPC.Transaction

  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.with_index(elixir) |> Enum.map(&Transaction.elixir_to_params/1)
  end
end
