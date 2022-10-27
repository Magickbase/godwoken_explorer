defmodule GodwokenIndexer.Worker.CheckContractCode do
  @moduledoc """
  Find polyjuice_contract with nil contract_code then send to `GodwokenIndexer.Worker.ImportContractCode`.
  """
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, Account}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    from(a in Account, where: a.type == :polyjuice_contract and is_nil(a.contract_code))
    |> Repo.all()
    |> Enum.each(fn account ->
      %{"block_number" => "latest", "address" => account.eth_address}
      |> GodwokenIndexer.Worker.ImportContractCode.new()
      |> Oban.insert()
    end)

    :ok
  end
end
