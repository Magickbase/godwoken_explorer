defmodule Mix.Tasks.UpdateTokenInstanceMetadata do
  @moduledoc "Printed when the user requests `mix help update_token_instance_metadata`"

  @shortdoc "running with limit/start/walk args `mix update_token_instance_metadata 350000 0 500` to updating udt balance and current udt balance with token_id/token_type"

  alias GodwokenExplorer.TokenTransfer
  alias GodwokenExplorer.Repo
  alias GodwokenIndexer.Transform.TokenBalances
  alias GodwokenExplorer.UDT

  alias GodwokenIndexer.Worker.ERC721ERC1155InstanceMetadata

  import Ecto.Query
  use Mix.Task

  require Logger

  # @chunk_size 100

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    args_return =
      case args do
        [limit, start, walk] ->
          %{
            limit: limit |> String.to_integer(),
            start: start |> String.to_integer(),
            walk: walk |> String.to_integer()
          }

        [limit, start] ->
          %{
            limit: limit |> String.to_integer(),
            start: start |> String.to_integer()
          }

        [limit] ->
          %{
            limit: limit |> String.to_integer()
          }

        _ ->
          %{}
      end

    IO.inspect(
      "mix run update_token_instance_metadata task with args limit/start/walk ===>: #{inspect(args_return)}"
    )

    limit_value = Map.get(args_return, :limit, 500)
    start = Map.get(args_return, :start, 0)
    walk = Map.get(args_return, :walk, 100)

    return = iterate_token_transfer(limit_value, start, walk)
    IO.inspect(return)
  end

  def iterate_token_transfer(limit_value, start, walk) do
    if start + walk <= limit_value do
      return = get_token_transfer_with_base(limit_value, start, walk)
      do_update_token_instance_metadata(return)
      start = start + walk
      iterate_token_transfer(limit_value, start, walk)
    else
      :skip
    end
  end

  def do_update_token_instance_metadata(token_transfers) do
    {_without_token_ids, with_token_ids} =
      TokenBalances.params_set(%{token_transfers_params: token_transfers})
      |> Enum.split_with(fn udt_balance -> is_nil(Map.get(udt_balance, :token_id)) end)

    jobs = length(with_token_ids)
    IO.inspect("processing #{jobs} jobs")

    with_token_ids =
      with_token_ids
      |> Enum.map(fn tt ->
        %{
          "token_contract_address_hash" => tt.token_contract_address_hash,
          "token_id" => tt.token_id |> Decimal.to_integer()
        }
      end)

    if length(with_token_ids) > 0 do
      Enum.chunk_every(with_token_ids, 100)
      |> Enum.each(fn args ->
        Task.async_stream(
          args,
          fn arg ->
            ERC721ERC1155InstanceMetadata.do_perform(arg)
          end,
          timeout: :infinity
        )
        |> Enum.to_list()
        |> Enum.filter(fn {a, _} -> a != :ok end)
        |> IO.inspect(label: "fail fetch ===> ")
      end)
    else
      :skip
    end
  end

  def get_token_transfer_with_base(limit, start, walk) do
    running_args = %{
      limit: limit,
      start: start,
      walk: walk
    }

    IO.inspect("get_token_transfer_with_base running args ===>: #{inspect(running_args)}")

    unbound_max_range =
      if walk + start > limit do
        limit
      else
        walk + start
      end

    query =
      from(tt in TokenTransfer,
        where: tt.block_number >= ^start and tt.block_number < ^unbound_max_range,
        inner_join: u in UDT,
        on: u.contract_address_hash == tt.token_contract_address_hash,
        where: u.eth_type in [:erc721, :erc1155],
        select: %{
          block_number: tt.block_number,
          token_id: tt.token_id,
          token_type: u.eth_type,
          token_contract_address_hash: tt.token_contract_address_hash,
          from_address_hash: tt.from_address_hash,
          to_address_hash: tt.to_address_hash,
          token_ids: tt.token_ids
        }
      )

    Repo.all(query)
    |> Enum.map(fn map ->
      token_type =
        if map[:token_type] do
          map[:token_type]
        else
          # raise "query udt type error with: #{inspect(map.token_contract_address_hash |> to_string)}"
          if map[:token_ids] do
            :erc1155
          else
            if map[:token_id] do
              Logger.error(fn -> "cannot confirm token transfer's eth type" end)
              # :erc721 or erc1155
              raise "query udt type error with: #{inspect(map.token_contract_address_hash |> to_string)}"
            else
              :erc20
            end
          end
        end

      %{
        block_number: map[:block_number],
        token_id: map[:token_id],
        token_ids: map[:token_ids],
        token_type: token_type,
        token_contract_address_hash: map[:token_contract_address_hash] |> to_string,
        from_address_hash: map[:from_address_hash] |> to_string,
        to_address_hash: map[:to_address_hash] |> to_string
      }
    end)
  end
end
