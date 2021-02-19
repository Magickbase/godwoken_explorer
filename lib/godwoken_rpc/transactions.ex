defmodule GodwokenRPC.Transactions do
  alias GodwokenRPC.Transaction

  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.map(elixir, &Transaction.elixir_to_params/1)
  end
end
