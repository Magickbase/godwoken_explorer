defmodule GodwokenRPC.WithdrawalRequests do
  @moduledoc """
  Withdrawal Requests format as returned by `GodwokenRPC.Block.ByNumber` module.
  """

  alias GodwokenRPC.WithdrawalRequest

  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.map(elixir, &WithdrawalRequest.elixir_to_params/1)
  end
end
