defmodule GodwokenExplorer.Etherscan do
  @moduledoc """
  The etherscan context.
  """

  import Ecto.Query, only: [from: 2, where: 3, or_where: 3, subquery: 1, order_by: 3]

  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.{Account, Repo, Polyjuice, Transaction, TokenTransfer, UDT}
  alias GodwokenExplorer.Account.{CurrentBridgedUDTBalance, CurrentUDTBalance}
  alias GodwokenExplorer.Etherscan.Logs

  @default_options %{
    order_by_direction: :desc,
    page_number: 1,
    page_size: 10_000,
    start_block: nil,
    end_block: nil,
    start_timestamp: nil,
    end_timestamp: nil
  }

  @spec page_size_max :: pos_integer()
  def page_size_max do
    @default_options.page_size
  end

  @spec list_transactions(Hash.Address.t()) :: [map()]
  def list_transactions(
        %Hash{byte_count: unquote(Hash.Address.byte_count())} = address_hash,
        options \\ @default_options
      ) do
    options = Map.merge(@default_options, options)
    %Account{id: id} = Repo.get_by(Account, eth_address: address_hash)

    query =
      from(
        t in Transaction,
        inner_join: b in assoc(t, :block),
        order_by: [
          {^options.order_by_direction, t.block_number},
          {^options.order_by_direction, t.index}
        ],
        limit: ^options.page_size,
        offset: ^offset(options),
        select: t.hash
      )

    tx_hashes =
      query
      |> where_address_match(id, options)
      |> where_start_block_match(options)
      |> where_end_block_match(options)
      |> Repo.all()

    Transaction.list_transaction_by_tx_hash(tx_hashes)
    |> order_by([t], desc: t.block_number, desc: t.index)
    |> Repo.all()
  end

  @token_transfer_fields ~w(
    block_number
    block_hash
    token_contract_address_hash
    transaction_hash
    from_address_hash
    to_address_hash
    amount
  )a

  @spec list_token_transfers(Hash.Address.t(), Hash.Address.t() | nil, map()) :: [map()]
  def list_token_transfers(
        %Hash{byte_count: unquote(Hash.Address.byte_count())} = address_hash,
        contract_address_hash,
        options \\ @default_options
      ) do
    options = Map.merge(@default_options, options)
    %Account{eth_address: eth_address} = Repo.get_by(Account, eth_address: address_hash)

    tt_query =
      from(
        tt in TokenTransfer,
        left_join: tkn in UDT,
        on: tkn.contract_address_hash == tt.token_contract_address_hash,
        where: tt.from_address_hash == ^eth_address,
        or_where: tt.to_address_hash == ^eth_address,
        order_by: [
          {^options.order_by_direction, tt.block_number},
          {^options.order_by_direction, tt.log_index}
        ],
        limit: ^options.page_size,
        offset: ^offset(options),
        select:
          merge(map(tt, ^@token_transfer_fields), %{
            token_id: tkn.id,
            token_name: tkn.name,
            token_symbol: tkn.symbol,
            token_decimals: tkn.decimal,
            token_log_index: tt.log_index
          })
      )

    tt_specific_token_query =
      tt_query
      |> where_contract_address_match(contract_address_hash)

    wrapped_query =
      from(
        tt in subquery(tt_specific_token_query),
        inner_join: t in Transaction,
        on:
          tt.transaction_hash == t.eth_hash and tt.block_number == t.block_number and
            tt.block_hash == t.block_hash,
        inner_join: p in Polyjuice,
        on: p.tx_hash == t.hash,
        inner_join: b in assoc(t, :block),
        order_by: [
          {^options.order_by_direction, tt.block_number},
          {^options.order_by_direction, tt.token_log_index}
        ],
        select: %{
          token_contract_address_hash: tt.token_contract_address_hash,
          transaction_hash: tt.transaction_hash,
          from_address_hash: tt.from_address_hash,
          to_address_hash: tt.to_address_hash,
          amount: tt.amount,
          transaction_nonce: t.nonce,
          transaction_index: p.transaction_index,
          transaction_gas: p.gas_limit,
          transaction_gas_price: p.gas_price,
          transaction_gas_used: p.gas_used,
          transaction_input: p.input,
          block_hash: b.hash,
          block_number: b.number,
          block_timestamp: b.timestamp,
          token_id: tt.token_id,
          token_name: tt.token_name,
          token_symbol: tt.token_symbol,
          token_decimals: tt.token_decimals,
          token_log_index: tt.token_log_index
        }
      )

    wrapped_query
    |> where_start_block_match(options)
    |> where_end_block_match(options)
    |> Repo.all()
  end

  @spec list_logs(map()) :: [map()]
  def list_logs(filter), do: Logs.list_logs(filter)

  defp where_address_match(query, id, _) do
    query
    |> where([t], t.from_account_id == ^id)
    |> or_where([t], t.to_account_id == ^id)
  end

  def get_token_balance(
        %Hash{byte_count: unquote(Hash.Address.byte_count())} = contract_address_hash,
        %Hash{byte_count: unquote(Hash.Address.byte_count())} = address_hash
      ) do
    udt_balance =
      from(cub in CurrentUDTBalance,
        where: cub.token_contract_address_hash == ^contract_address_hash,
        where: cub.address_hash == ^address_hash,
        select: {cub.value, cub.updated_at}
      )
      |> Repo.one()

    with udt_script_hash when not is_nil(udt_script_hash) <-
           from(u in UDT,
             join: a in Account,
             on: a.id == u.bridge_account_id,
             where: u.type == :bridge and a.eth_address == ^contract_address_hash,
             select: a.script_hash
           )
           |> Repo.one(),
         bridged_udt_balance when not is_nil(bridged_udt_balance) <-
           from(cbub in CurrentBridgedUDTBalance,
             where: cbub.udt_script_hash == ^udt_script_hash,
             where: cbub.address_hash == ^address_hash,
             select: {cbub.value, cbub.updated_at}
           )
           |> Repo.one() do
      [udt_balance, bridged_udt_balance] |> Enum.sort_by(&elem(&1, 1)) |> List.first() |> elem(0)
    else
      _ ->
        if is_tuple(udt_balance), do: elem(udt_balance, 0)
    end
  end

  defp where_start_block_match(query, %{start_block: nil}), do: query

  defp where_start_block_match(query, %{start_block: start_block}) do
    where(query, [..., block], block.number >= ^start_block)
  end

  defp where_end_block_match(query, %{end_block: nil}), do: query

  defp where_end_block_match(query, %{end_block: end_block}) do
    where(query, [..., block], block.number <= ^end_block)
  end

  defp where_contract_address_match(query, nil), do: query

  defp where_contract_address_match(query, contract_address_hash) do
    where(query, [tt, _], tt.token_contract_address_hash == ^contract_address_hash)
  end

  defp offset(options), do: (options.page_number - 1) * options.page_size
end
