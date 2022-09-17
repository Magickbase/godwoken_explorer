defmodule GodwokenExplorer.Graphql.Resolvers.TokenTransfer do
  alias GodwokenExplorer.{TokenTransfer, Polyjuice, Account, UDT, Block, Transaction}

  alias GodwokenExplorer.Repo

  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [cursor_order_sorter: 3]

  import GodwokenExplorer.Graphql.Resolvers.Common,
    only: [paginate_query: 3, query_with_block_age_range: 2]

  @sorter_fields [:transaction_hash, :log_index, :block_number]

  def erc20_token_transfers(_parent, %{input: input}, _resolution) do
    return =
      from(tt in TokenTransfer)
      |> where([tt], is_nil(tt.token_id) and is_nil(tt.token_ids))
      |> query_token_transfers(input, :erc20)
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: [:transaction_hash, :log_index]
      })

    {:ok, return}
  end

  def erc721_token_transfers(_parent, %{input: input}, _resolution) do
    return =
      from(tt in TokenTransfer)
      |> where([tt], not is_nil(tt.token_id))
      |> join(:inner, [tt], u in UDT,
        on: tt.token_contract_address_hash == u.contract_address_hash and u.eth_type == :erc721
      )
      |> query_token_transfers(input, :erc721)
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: [:transaction_hash, :log_index]
      })

    {:ok, return}
  end

  def erc1155_token_transfers(_parent, %{input: input}, _resolution) do
    return =
      from(tt in TokenTransfer)
      |> where([tt], not is_nil(tt.token_ids) or not is_nil(tt.token_id))
      |> join(:inner, [tt], u in UDT,
        on: tt.token_contract_address_hash == u.contract_address_hash and u.eth_type == :erc1155
      )
      |> query_token_transfers(input, :erc1155)
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: [:transaction_hash, :log_index]
      })

    {:ok, return}
  end

  def polyjuice(%TokenTransfer{transaction_hash: transaction_hash}, _args, _resolution) do
    query =
      from(t in Transaction, where: t.eth_hash == ^transaction_hash)
      |> join(:inner, [t], p in Polyjuice, on: p.tx_hash == t.hash)
      |> select([_, p], p)

    return = Repo.one(query)
    {:ok, return}
  end

  def block(%TokenTransfer{block_hash: block_hash}, _args, _resolution) do
    if block_hash do
      return = Repo.get(Block, block_hash)
      {:ok, return}
    else
      {:ok, nil}
    end
  end

  def from_address(%TokenTransfer{from_address_hash: from_address_hash}, _args, _resolution) do
    {:ok, from_address_hash}
  end

  def to_address(%TokenTransfer{to_address_hash: to_address_hash}, _args, _resolution) do
    {:ok, to_address_hash}
  end

  def from_account(%TokenTransfer{from_address_hash: from_address_hash}, _args, _resolution) do
    if from_address_hash do
      return = Repo.get_by(Account, eth_address: from_address_hash)
      {:ok, return}
    else
      {:ok, nil}
    end
  end

  def to_account(%TokenTransfer{to_address_hash: to_address_hash}, _args, _resolution) do
    if to_address_hash do
      return = Repo.get_by(Account, eth_address: to_address_hash)
      {:ok, return}
    else
      {:ok, nil}
    end
  end

  def udt(
        %TokenTransfer{token_contract_address_hash: token_contract_address_hash},
        _args,
        _resolution
      ) do
    udt = UDT.get_by_contract_address(token_contract_address_hash)
    {:ok, udt}
  end

  def transaction(%TokenTransfer{transaction_hash: transaction_hash}, _args, _resolution) do
    return = Repo.one(from t in Transaction, where: t.eth_hash == ^transaction_hash)
    {:ok, return}
  end

  defp query_token_transfers(query, input, token_type) do
    conditions =
      Enum.reduce(input, true, fn arg, acc ->
        case arg do
          {:transaction_hash, value} ->
            dynamic([tt], ^acc and tt.transaction_hash == ^value)

          {:token_contract_address_hash, value} ->
            dynamic([tt], ^acc and tt.token_contract_address_hash == ^value)

          {:start_block_number, value} ->
            dynamic([tt], ^acc and tt.block_number >= ^value)

          {:end_block_number, value} ->
            dynamic([tt], ^acc and tt.block_number <= ^value)

          {:token_id, value} ->
            case token_type do
              :erc721 ->
                dynamic([tt], ^acc and tt.token_id == ^value)

              :erc1155 ->
                dynamic(
                  [tt],
                  ^acc and
                    (^value in tt.token_ids or
                       (is_nil(tt.token_ids) and tt.token_id == ^value))
                )

              :erc20 ->
                acc
            end

          _ ->
            acc
        end
      end)

    conditions =
      case {input[:from_address], input[:to_address]} do
        {nil, nil} ->
          conditions

        {nil, to_address} when not is_nil(to_address) ->
          dynamic([tt], ^conditions and tt.to_address_hash == ^to_address)

        {from_address, nil} when not is_nil(from_address) ->
          dynamic([tt], ^conditions and tt.from_address_hash == ^from_address)

        {from_address, to_address} ->
          if input[:combine_from_to] do
            dynamic(
              [tt],
              ^conditions and
                (tt.from_address_hash == ^from_address or
                   tt.to_address_hash == ^to_address)
            )
          else
            dynamic(
              [tt],
              ^conditions and tt.from_address_hash == ^from_address and
                tt.to_address_hash == ^to_address
            )
          end
      end

    query
    |> where([tt], ^conditions)
    |> join(:inner, [tt], b in Block, as: :block, on: b.hash == tt.block_hash)
    |> query_with_block_age_range(input)
    |> token_transfers_order_by(input)
  end

  defp token_transfers_order_by(query, input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      order_params = cursor_order_sorter(sorter, :order, @sorter_fields)
      base = Enum.map(order_params, fn {_, e} -> e end)
      extend = [:transaction_hash, :log_index] -- base
      extend = extend |> Enum.map(fn e -> {:asc, e} end)

      order_params = order_params ++ extend
      order_by(query, [u], ^order_params)
    else
      order_by(query, [u], [:block_number, :transaction_hash, :log_index])
    end
  end

  defp paginate_cursor(input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      cursor_params = cursor_order_sorter(sorter, :cursor, @sorter_fields)
      base = Enum.map(cursor_params, fn {e, _} -> e end)
      extend = [:transaction_hash, :log_index] -- base
      extend = extend |> Enum.map(fn e -> {e, :asc} end)

      cursor_params ++ extend
    else
      [:block_number, :transaction_hash, :log_index]
    end
  end
end
