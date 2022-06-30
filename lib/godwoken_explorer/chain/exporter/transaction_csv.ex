defmodule GodwokenExplorer.Chain.Exporter.TransactionCsv do
  alias NimbleCSV.RFC4180

  def export(results) do
    results
    |> to_csv_format()
    |> dump_to_stream()
  end

  defp dump_to_stream(transactions) do
    transactions
    |> RFC4180.dump_to_stream()
  end

  defp to_csv_format(transactions) do
    row_names = [
      "TxHash",
      "BlockNumber",
      "UnixTimestamp",
      "FromAddress",
      "ToAddress",
      "Value",
      "Type",
      "PolyjuiceStatus",
      "BlockStatus"
    ]

    transaction_lists =
      transactions
      |> Stream.map(fn transaction ->
        [
          transaction[:hash],
          transaction[:block_number],
          transaction[:timestamp],
          transaction[:from],
          transaction[:to_alias],
          transaction[:value],
          transaction[:type],
          transaction[:polyjuice_status],
          transaction[:status]
        ]
      end)

    Stream.concat([row_names], transaction_lists)
  end
end
