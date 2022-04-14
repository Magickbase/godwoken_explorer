defmodule GodwokenRPC.Transactions do
  alias GodwokenRPC.Transaction

  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.with_index(elixir) |> Enum.map(&Transaction.elixir_to_params/1)
  end
end
