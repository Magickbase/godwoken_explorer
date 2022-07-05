defmodule GodwokenRPC.Transaction.Receipt do
  import GodwokenRPC.Util, only: [hex_to_number: 1]

  def elixir_to_logs(%{"logs" => logs, "transaction_hash" => transaction_hash}),
    do: logs |> Enum.map(&Map.put(&1, :transaction_hash, transaction_hash))

  def to_elixir(receipt) when is_map(receipt) do
    receipt
    |> Enum.reduce({:ok, %{}}, &entry_reducer/2)
    |> ok!(receipt)
  end

  defp entry_reducer(entry, acc) do
    entry
    |> entry_to_elixir()
    |> elixir_reducer(acc)
  end

  defp elixir_reducer({:ok, {key, elixir_value}}, {:ok, elixir_map}) do
    {:ok, Map.put(elixir_map, key, elixir_value)}
  end

  defp elixir_reducer({:ok, {_, _}}, {:error, _reasons} = acc_error), do: acc_error
  defp elixir_reducer({:error, reason}, {:ok, _}), do: {:error, [reason]}
  defp elixir_reducer({:error, reason}, {:error, reasons}), do: {:error, [reason | reasons]}
  defp elixir_reducer(:ignore, acc), do: acc

  defp ok!({:ok, elixir}, _receipt), do: elixir

  defp ok!({:error, reasons}, receipt) do
    formatted_errors = Enum.map_join(reasons, "\n", fn reason -> "  #{inspect(reason)}" end)

    raise ArgumentError,
          """
          Could not convert receipt to elixir

          Receipt:
            #{inspect(receipt)}

          Errors:
          #{formatted_errors}
          """
  end

  # double check that no new keys are being missed by requiring explicit match for passthrough
  # `t:GodwokenRPC.address/0` and `t:GodwokenRPC.hash/0` pass through as `Explorer.Chain` can verify correct
  # hash format
  # gas is passed in from the `t:GodwokenRPC.Transaction.params/0` to allow pre-Byzantium status to be derived
  defp entry_to_elixir({"logs" = key, logs}) do
    {:ok,
     {key,
      logs
      |> Enum.with_index()
      |> Enum.map(fn {log, index} ->
        elixir_to_params(log, index)
      end)}}
  end

  defp entry_to_elixir({"transaction_hash" = key, transaction_hash}) do
    {:ok, {key, transaction_hash}}
  end

  # Nethermind field
  defp entry_to_elixir({"error", _}) do
    :ignore
  end

  defp entry_to_elixir({key, _})
       when key in ~w(exit_code post_state tx_witness_hash read_data_hashes) do
    :ignore
  end

  defp entry_to_elixir({key, value}) do
    {:error, {:unknown_key, %{key: key, value: value}}}
  end

  defp elixir_to_params(
         %{
           "account_id" => account_id,
           "service_flag" => service_flag,
           "data" => data
         } = log,
         index
       ) do
    %{
      account_id: hex_to_number(account_id),
      index: index,
      service_flag: hex_to_number(service_flag),
      data: data
    }
    |> put_type(log)
  end

  defp put_type(params, %{"service_flag" => service_flag}) do
    type =
      cond do
        service_flag == "0x0" -> :sudt_transfer
        service_flag == "0x1" -> :sudt_pay_fee
        service_flag == "0x2" -> :polyjuice_system
        service_flag == "0x3" -> :polyjuce_user
      end

    Map.put(params, :type, type)
  end

  defp put_type(params, _), do: params
end
