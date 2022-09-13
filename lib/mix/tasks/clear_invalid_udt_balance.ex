defmodule Mix.Tasks.ClearInvalidUdtBalance do
  @moduledoc "Printed when the user requests `mix help clear_invalid_udt_balance`"
  @shortdoc " `mix clear_invalid_udt_balance`"

  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Account.UDTBalance
  import Ecto.Query

  use Mix.Task

  # require Logger

  # @chunk_size 100

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    query = from u in UDTBalance, where: is_nil(u.token_type)
    Repo.delete_all(query) |> IO.inspect()

    [
      {"0x310a1f73379a658ef0eb9c4e5bd1006a24a5ad79", "0x191a6831f73d15fadb3944b8f783c6f99794fe6e",
       37337},
      {"0x310a1f73379a658ef0eb9c4e5bd1006a24a5ad79", "0x191a6831f73d15fadb3944b8f783c6f99794fe6e",
       41457},
      {"0x310a1f73379a658ef0eb9c4e5bd1006a24a5ad79", "0x191a6831f73d15fadb3944b8f783c6f99794fe6e",
       41462},
      {"0x310a1f73379a658ef0eb9c4e5bd1006a24a5ad79", "0x3089ea87cd8dc04e0985e0c0da272e399a7c289a",
       30498},
      {"0x310a1f73379a658ef0eb9c4e5bd1006a24a5ad79", "0x3089ea87cd8dc04e0985e0c0da272e399a7c289a",
       37337},
      {"0x310a1f73379a658ef0eb9c4e5bd1006a24a5ad79", "0xdf93f297e0e95025ab212ecfbd12014e08125902",
       41457},
      {"0x310a1f73379a658ef0eb9c4e5bd1006a24a5ad79", "0xdf93f297e0e95025ab212ecfbd12014e08125902",
       41462}
    ]

    %{
      token_contract_address_hash: "0x310a1f73379a658ef0eb9c4e5bd1006a24a5ad79",
      address_hash: "0x3089ea87cd8dc04e0985e0c0da272e399a7c289a",
      block_number: 37337
    }

    query = from u in UDTBalance, where: u.token_type == :erc721 and u.value > 1
    # Repo.update_all(query, set: [value: nil]) |> IO.inspect()
    Repo.all(query) |> length() |> IO.inspect()
  end
end
