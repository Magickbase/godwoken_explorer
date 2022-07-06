defmodule GodwokenExplorer.Chain.Exporter.DepositWithdrawalCsv do
  alias NimbleCSV.RFC4180

  def export(results) do
    results
    |> to_csv_format()
    |> dump_to_stream()
  end

  defp dump_to_stream(deposit_withdrawals) do
    deposit_withdrawals
    |> RFC4180.dump_to_stream()
  end

  defp to_csv_format(deposit_withdrawals) do
    row_names = [
      "Type",
      "Value",
      "UDT Symbol",
      "Capacity",
      "UnixTimestamp",
      "Address",
      "Layer1 TxnHash",
      "Block Number"
    ]

    deposit_withdrawal_lists =
      deposit_withdrawals
      |> Stream.map(fn deposit_withdrawal ->
        [
          deposit_withdrawal[:type],
          deposit_withdrawal[:value],
          deposit_withdrawal[:udt_symbol],
          deposit_withdrawal[:capacity],
          deposit_withdrawal[:timestamp],
          deposit_withdrawal[:eth_address],
          deposit_withdrawal[:layer1_tx_hash],
          deposit_withdrawal[:block_number]
        ]
      end)

    Stream.concat([row_names], deposit_withdrawal_lists)
  end
end
