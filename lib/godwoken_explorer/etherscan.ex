defmodule GodwokenExplorer.Etherscan do
  @moduledoc """
  The etherscan context.
  """

  import Ecto.Query, only: [from: 2, where: 3, or_where: 3, subquery: 1, order_by: 3]

  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.{Account, Repo, Polyjuice, Transaction, TokenTransfer, UDT}

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
    %Account{id: id} = Account.search(address_hash)

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
    %Account{short_address: short_address} = Account.search(address_hash)

    tt_query =
      from(
        tt in TokenTransfer,
        join: a4 in Account,
        on: a4.short_address == tt.token_contract_address_hash,
        left_join: tkn in UDT,
        on: tkn.bridge_account_id == a4.id,
        where: tt.from_address_hash == ^short_address,
        or_where: tt.to_address_hash == ^short_address,
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
        left_join: a1 in Account,
        on: a1.short_address == tt.from_address_hash,
        left_join: a2 in Account,
        on: a2.short_address == tt.to_address_hash,
        inner_join: t in Transaction,
        on:
          tt.transaction_hash == t.hash and tt.block_number == t.block_number and
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
          from_address_hash:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'hex')
          WHEN ? in ('user') THEN encode(?, 'hex')
        ELSE encode(?, 'hex') END",
              a1,
              tt.from_address_hash,
              a1.type,
              a1.eth_address,
              a1.short_address
            ),
          to_address_hash:
            fragment(
              "CASE WHEN ? IS NULL THEN encode(?, 'hex')
          WHEN ? in ('user') THEN encode(?, 'hex')
        ELSE encode(?, 'hex') END",
              a2,
              tt.to_address_hash,
              a2.type,
              a2.eth_address,
              a2.short_address
            ),
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

  defp where_address_match(query, id, _) do
    query
    |> where([t], t.from_account_id == ^id)
    |> or_where([t], t.to_account_id == ^id)
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
