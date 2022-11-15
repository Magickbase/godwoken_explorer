defmodule GodwokenExplorer.Chain.Cache.TokenExchangeRate do
  @moduledoc """
  Caches Token USD exchange_rate.
  """
  use GenServer

  alias GodwokenExplorer.Counters.Helper
  alias GodwokenExplorer.ExchangeRates.Source

  @cache_name :token_exchange_rate
  @last_update_key "last_update"

  @enable_consolidation true

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    create_cache_table()

    {:ok, %{consolidate?: enable_consolidation?()}, {:continue, :ok}}
  end

  @impl true
  def handle_continue(:ok, %{consolidate?: true} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_continue(:ok, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:consolidate, state) do
    {:noreply, state}
  end

  def cache_key(symbol_or_address_hash_str) do
    "token_symbol_exchange_rate_#{symbol_or_address_hash_str}"
  end

  # fetching by symbol is not recommended to use because of possible collisions
  # fetch() should be used instead
  def fetch_by_symbol(symbol) do
    if cache_expired?(symbol) || value_is_empty?(symbol) do
      Task.start_link(fn ->
        update_cache_by_symbol(symbol)
      end)
    end

    cached_value =
      symbol
      |> cache_key()
      |> fetch_from_cache()

    cached_value
  end

  def cache_name, do: @cache_name

  defp cache_expired?(symbol_or_address_hash_str) do
    cache_period = token_exchange_rate_cache_period()
    updated_at = fetch_from_cache("#{cache_key(symbol_or_address_hash_str)}_#{@last_update_key}")

    cond do
      is_nil(updated_at) -> true
      Helper.current_time() - updated_at > cache_period -> true
      true -> false
    end
  end

  defp value_is_empty?(symbol_or_address_hash_str) do
    value =
      symbol_or_address_hash_str
      |> cache_key()
      |> fetch_from_cache()

    is_nil(value) || value == 0
  end

  defp update_cache_by_symbol(symbol) do
    put_into_cache("#{cache_key(symbol)}_#{@last_update_key}", Helper.current_time())

    exchange_rate = fetch_token_exchange_rate(symbol, true)

    put_into_cache(cache_key(symbol), exchange_rate)
  end

  def fetch_token_exchange_rate(symbol, internal_call? \\ false) do
    case Source.fetch_exchange_rates_for_token(symbol) do
      {:ok, [rates]} ->
        rates.usd_value

      {:error, "Could not find coin with the given id"} ->
        if internal_call?, do: :not_found_coingecko, else: nil

      _ ->
        nil
    end
  end

  defp fetch_from_cache(key) do
    result = Helper.fetch_from_cache(key, @cache_name)

    if result == 0 do
      Decimal.new(0)
    else
      result
    end
  end

  def put_into_cache(key, value) do
    if cache_table_exists?() do
      :ets.insert(@cache_name, {key, value})
    end
  end

  def cache_table_exists? do
    :ets.whereis(@cache_name) !== :undefined
  end

  def create_cache_table do
    Helper.create_cache_table(@cache_name)
  end

  def enable_consolidation?, do: @enable_consolidation

  defp token_exchange_rate_cache_period do
    Helper.cache_period("CACHE_TOKEN_EXCHANGE_RATE_PERIOD", 1)
  end
end
