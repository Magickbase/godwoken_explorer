defmodule GodwokenRPC.WithdrawalRequests do
  alias GodwokenRPC.WithdrawalRequest

  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.map(elixir, &WithdrawalRequest.elixir_to_params/1)
  end
end
