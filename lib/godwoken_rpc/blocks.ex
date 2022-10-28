defmodule GodwokenRPC.Blocks do
  @moduledoc """
  Blocks format as returned by `GodwokenRPC.Block.ByNumber` module.
  """

  alias GodwokenRPC.{Block, Transactions, WithdrawalRequests}

  defstruct blocks_params: [],
            transactions_params: [],
            withdrawal_params: [],
            errors: []

  def requests(id_to_params, request) when is_map(id_to_params) and is_function(request, 1) do
    Enum.map(id_to_params, fn {id, params} ->
      params
      |> Map.put(:id, id)
      |> request.()
    end)
  end

  def from_responses(responses, id_to_params) when is_list(responses) and is_map(id_to_params) do
    %{errors: errors, blocks: blocks} =
      responses
      |> Enum.map(&Block.from_response(&1, id_to_params))
      |> Enum.reduce(%{errors: [], blocks: []}, fn
        {:ok, block}, %{blocks: blocks} = acc ->
          %{acc | blocks: [block | blocks]}

        {:error, error}, %{errors: errors} = acc ->
          %{acc | errors: [error | errors]}
      end)

    elixir_transactions = elixir_to_transactions(blocks)
    withdrawal_requests = elixir_to_withdrawal_requests(blocks)
    transactions_params = Transactions.elixir_to_params(elixir_transactions)
    withdrawal_params = WithdrawalRequests.elixir_to_params(withdrawal_requests)

    blocks_params = elixir_to_params(blocks)

    %__MODULE__{
      errors: errors,
      blocks_params: blocks_params,
      transactions_params: transactions_params,
      withdrawal_params: withdrawal_params
    }
  end

  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.map(elixir, &Block.elixir_to_params/1)
  end

  def elixir_to_transactions(elixir) when is_list(elixir) do
    Enum.flat_map(elixir, &Block.elixir_to_transactions/1)
  end

  def elixir_to_withdrawal_requests(elixir) when is_list(elixir) do
    Enum.flat_map(elixir, &Block.elixir_to_withdrawal_requests/1)
  end
end
