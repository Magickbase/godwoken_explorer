defmodule GodwokenIndexer.Fetcher.UDTBalances do
  require Logger

  alias GodwokenExplorer.Token.BalanceReader

  @erc1155_balance_function_abi [
    %{
      "constant" => true,
      "inputs" => [
        %{"name" => "_owner", "type" => "address"},
        %{"name" => "_id", "type" => "uint256"}
      ],
      "name" => "balanceOf",
      "outputs" => [%{"name" => "", "type" => "uint256"}],
      "payable" => false,
      "stateMutability" => "view",
      "type" => "function"
    }
  ]

  def fetch_token_balances_from_blockchain([]), do: {:ok, []}

  def fetch_token_balances_from_blockchain(token_balances) do
    Logger.debug("fetching token balances", count: Enum.count(token_balances))

    regular_token_balances =
      token_balances
      |> Enum.filter(fn request ->
        if Map.has_key?(request, :token_type) do
          request.token_type !== :erc1155
        else
          true
        end
      end)

    erc1155_token_balances =
      token_balances
      |> Enum.filter(fn request ->
        if Map.has_key?(request, :token_type) do
          request.token_type == :erc1155
        else
          false
        end
      end)

    requested_regular_token_balances =
      regular_token_balances
      |> BalanceReader.get_balances_of()
      |> Stream.zip(regular_token_balances)
      |> Enum.map(fn {result, token_balance} -> set_token_balance_value(result, token_balance) end)

    requested_erc1155_token_balances =
      erc1155_token_balances
      |> BalanceReader.get_balances_of_with_abi(@erc1155_balance_function_abi)
      |> Stream.zip(erc1155_token_balances)
      |> Enum.map(fn {result, token_balance} -> set_token_balance_value(result, token_balance) end)

    requested_token_balances =
      requested_regular_token_balances ++ requested_erc1155_token_balances

    fetched_token_balances = Enum.filter(requested_token_balances, &ignore_request_with_errors/1)

    {:ok, fetched_token_balances}
  end

  def to_address_current_token_balances(address_token_balances)
      when is_list(address_token_balances) do
    address_token_balances
    |> Enum.group_by(fn %{
                          address_hash: address_hash,
                          token_contract_address_hash: token_contract_address_hash,
                          token_id: token_id
                        } ->
      {address_hash, token_contract_address_hash, token_id}
    end)
    |> Enum.map(fn {_, grouped_address_token_balances} ->
      Enum.max_by(grouped_address_token_balances, fn %{block_number: block_number} ->
        block_number
      end)
    end)
    |> Enum.sort_by(&{&1.token_contract_address_hash, &1.token_id, &1.address_hash})
  end

  defp set_token_balance_value({:ok, balance}, token_balance) do
    Map.merge(token_balance, %{value: balance, value_fetched_at: DateTime.utc_now(), error: nil})
  end

  defp set_token_balance_value({:error, error_message}, token_balance) do
    Map.merge(token_balance, %{value: nil, value_fetched_at: nil, error: error_message})
  end

  defp ignore_request_with_errors(%{value: nil, value_fetched_at: nil, error: _error}), do: false
  defp ignore_request_with_errors(_token_balance), do: true
end
