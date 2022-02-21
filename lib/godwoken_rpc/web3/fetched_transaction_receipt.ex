defmodule GodwokenRPC.Web3.FetchedTransactionReceipt do
  @doc """
  ## Examples

  {:ok,
  %{
    "blockHash" => "0x50e4ba7cbac965874c26e94f15cf92a8fda35c4c1230c9237abf871db186b84f",
    "blockNumber" => "0x2e0b3",
    "contractAddress" => "0x1da96ead31330a5336a881d0b22f48c2c15ef08b",
    "cumulativeGasUsed" => "0x143008",
    "from" => "0x3beb2e57b4f8c21a5a34227ebe314a7e00a6f9ae",
    "gasUsed" => "0x10765",
    "logs" => [
      %{
        "address" => "0x1da96ead31330a5336a881d0b22f48c2c15ef08b",
        "blockHash" => "0x50e4ba7cbac965874c26e94f15cf92a8fda35c4c1230c9237abf871db186b84f",
        "blockNumber" => "0x2e0b3",
        "data" => "0x0000000000000000000000000000000000000000000000000000000000000000",
        "logIndex" => "0x0",
        "removed" => false,
        "topics" => ["0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0",        "0x0000000000000000000000000000000000000000000000000000000000000000",        "0x000000000000000000000000068ac27b01fcb417ee54b79f64ae890bfb05433c"],
        "transactionHash" => "0x3f5cc0e2ed4fa0e2f75fa365657fee5ff267c87040fb8328edeb8ecdd7cfca68",
        "transactionIndex" => "0x48"
      }
    ],
    "logsBloom" => "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    "status" => "0x1",
    "to" => nil,
    "transactionHash" => "0x3f5cc0e2ed4fa0e2f75fa365657fee5ff267c87040fb8328edeb8ecdd7cfca68",
    "transactionIndex" => "0x48"
  }}
  """
  def request(%{id: id, tx_hash: tx_hash}) do
    GodwokenRPC.request(%{
      id: id,
      method: "eth_getTransactionReceipt",
      params: [tx_hash]
    })
  end


  def request(tx_hash) do
    GodwokenRPC.request(%{
      id: "0",
      method: "eth_getTransactionReceipt",
      params: [tx_hash]
    })
  end

end
