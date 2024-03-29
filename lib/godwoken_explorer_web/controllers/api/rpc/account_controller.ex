defmodule GodwokenExplorerWeb.API.RPC.AccountController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorerWeb.API.RPC.Helpers
  alias GodwokenExplorer.{Chain, Etherscan}
  alias GodwokenExplorer.Account.CurrentUDTBalance

  def balance(conn, params, template \\ :balance) do
    with {:address_param, {:ok, address_param}} <- fetch_address(params),
         {:format, {:ok, address_hashes}} <- to_address_hashes(address_param) do
      addresses = CurrentUDTBalance.get_ckb_balance(address_hashes)
      render(conn, template, %{addresses: addresses})
    else
      {:address_param, :error} ->
        conn
        |> put_status(200)
        |> render(:error, error: "Query parameter 'address' is required")

      {:format, :error} ->
        conn
        |> put_status(200)
        |> render(:error, error: "Invalid address hash")
    end
  end

  def balancemulti(conn, params) do
    balance(conn, params, :balancemulti)
  end

  def txlist(conn, params) do
    options = optional_params(params)

    with {:address_param, {:ok, address_param}} <- fetch_address(params),
         {:format, {:ok, address_hash}} <- to_address_hash(address_param),
         {:address, :ok} <- {:address, Chain.check_address_exists(address_hash)},
         {:ok, transactions} <- list_transactions(address_hash, options) do
      render(conn, :txlist, %{transactions: transactions})
    else
      {:address_param, :error} ->
        conn
        |> put_status(200)
        |> render(:error, error: "Query parameter 'address' is required")

      {:format, :error} ->
        conn
        |> put_status(200)
        |> render(:error, error: "Invalid address format")

      {_, :not_found} ->
        render(conn, :error, error: "No transactions found", data: [])
    end
  end

  def tokentx(conn, params) do
    options = optional_params(params)

    with {:address_param, {:ok, address_param}} <- fetch_address(params),
         {:format, {:ok, address_hash}} <- to_address_hash(address_param),
         {:contract_address, {:ok, contract_address_hash}} <-
           to_contract_address_hash(params["contractaddress"]),
         {:address, :ok} <- {:address, Chain.check_address_exists(address_hash)},
         {:ok, token_transfers} <-
           list_token_transfers(address_hash, contract_address_hash, options) do
      render(conn, :tokentx, %{token_transfers: token_transfers})
    else
      {:address_param, :error} ->
        render(conn, :error, error: "Query parameter address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid address format")

      {:contract_address, :error} ->
        render(conn, :error, error: "Invalid contract address format")

      {_, :not_found} ->
        render(conn, :error, error: "No token transfers found", data: [])
    end
  end

  @tokenbalance_required_params ~w(contractaddress address)

  def tokenbalance(conn, params) do
    with {:required_params, {:ok, fetched_params}} <-
           fetch_required_params(params, @tokenbalance_required_params),
         {:format, {:ok, validated_params}} <- to_valid_format(fetched_params, :tokenbalance) do
      token_balance = get_token_balance(validated_params)
      render(conn, "tokenbalance.json", %{token_balance: token_balance})
    else
      {:required_params, {:error, missing_params}} ->
        error = "Required query parameters missing: #{Enum.join(missing_params, ", ")}"
        render(conn, :error, error: error)

      {:format, {:error, param}} ->
        render(conn, :error, error: "Invalid #{param} format")
    end
  end

  @doc """
  Fetches required params. Returns error tuple if required params are missing.

  """
  @spec fetch_required_params(map(), list()) ::
          {:required_params, {:ok, map()} | {:error, [String.t(), ...]}}
  def fetch_required_params(params, required_params) do
    fetched_params = Map.take(params, required_params)

    result =
      if all_of_required_keys_found?(fetched_params, required_params) do
        {:ok, fetched_params}
      else
        missing_params = get_missing_required_params(fetched_params, required_params)
        {:error, missing_params}
      end

    {:required_params, result}
  end

  defp to_valid_format(params, :tokenbalance) do
    result =
      with {:ok, contract_address_hash} <- to_address_hash(params, "contractaddress"),
           {:ok, address_hash} <- to_address_hash(params, "address") do
        {:ok, %{contract_address_hash: contract_address_hash, address_hash: address_hash}}
      else
        {:error, _param_key} = error -> error
      end

    {:format, result}
  end

  defp to_address_hash(address_hash_string) do
    {:format, Chain.string_to_address_hash(address_hash_string)}
  end

  defp to_address_hash(params, param_key) do
    case Chain.string_to_address_hash(params[param_key]) do
      {:ok, address_hash} -> {:ok, address_hash}
      :error -> {:error, param_key}
    end
  end

  defp all_of_required_keys_found?(fetched_params, required_params) do
    Enum.all?(required_params, &Map.has_key?(fetched_params, &1))
  end

  defp get_missing_required_params(fetched_params, required_params) do
    fetched_keys = fetched_params |> Map.keys() |> MapSet.new()

    required_params
    |> MapSet.new()
    |> MapSet.difference(fetched_keys)
    |> MapSet.to_list()
  end

  defp fetch_address(params) do
    {:address_param, Map.fetch(params, "address")}
  end

  defp to_contract_address_hash(nil), do: {:contract_address, {:ok, nil}}

  defp to_contract_address_hash(address_hash_string) do
    {:contract_address, Chain.string_to_address_hash(address_hash_string)}
  end

  defp to_address_hashes(address_param) when is_binary(address_param) do
    address_param
    |> String.split(",")
    |> Enum.take(20)
    |> to_address_hashes()
  end

  defp to_address_hashes(address_param) when is_list(address_param) do
    address_hashes = address_param_to_address_hashes(address_param)

    if any_errors?(address_hashes) do
      {:format, :error}
    else
      {:format, {:ok, address_hashes}}
    end
  end

  defp address_param_to_address_hashes(address_param) do
    Enum.map(address_param, fn single_address ->
      case Chain.string_to_address_hash(single_address) do
        {:ok, address_hash} -> address_hash
        :error -> :error
      end
    end)
  end

  defp any_errors?(address_hashes) do
    Enum.any?(address_hashes, &(&1 == :error))
  end

  @spec optional_params(map()) :: map()
  def optional_params(params) do
    %{}
    |> put_order_by_direction(params)
    |> Helpers.put_pagination_options(params)
    |> put_start_block(params)
    |> put_end_block(params)
  end

  defp put_order_by_direction(options, params) do
    case params do
      %{"sort" => sort} when sort in ["asc", "desc"] ->
        order_by_direction = String.to_existing_atom(sort)
        Map.put(options, :order_by_direction, order_by_direction)

      _ ->
        options
    end
  end

  defp put_start_block(options, params) do
    with %{"startblock" => startblock_param} <- params,
         {start_block, ""} <- Integer.parse(startblock_param) do
      Map.put(options, :start_block, start_block)
    else
      _ ->
        options
    end
  end

  defp put_end_block(options, params) do
    with %{"endblock" => endblock_param} <- params,
         {end_block, ""} <- Integer.parse(endblock_param) do
      Map.put(options, :end_block, end_block)
    else
      _ ->
        options
    end
  end

  defp list_transactions(address_hash, options) do
    case Etherscan.list_transactions(address_hash, options) do
      [] -> {:error, :not_found}
      transactions -> {:ok, transactions}
    end
  end

  defp list_token_transfers(address_hash, contract_address_hash, options) do
    case Etherscan.list_token_transfers(address_hash, contract_address_hash, options) do
      [] ->
        {:error, :not_found}

      token_transfers ->
        {:ok, token_transfers}
    end
  end

  defp get_token_balance(%{
         contract_address_hash: contract_address_hash,
         address_hash: address_hash
       }) do
    case Etherscan.get_token_balance(contract_address_hash, address_hash) do
      nil -> 0
      token_balance -> token_balance
    end
  end
end
