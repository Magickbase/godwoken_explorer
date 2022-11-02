defmodule GodwokenExplorer.Graphql.Resolvers.Common do
  alias GodwokenExplorer.Repo
  import Ecto.Query

  def query_with_block_age_range({:error, _} = error, _input), do: error

  def query_with_block_age_range(query, input) do
    age_range_start = Map.get(input, :age_range_start)
    age_range_end = Map.get(input, :age_range_end)

    query =
      if age_range_start do
        query
        |> where([t], as(:block).timestamp >= ^age_range_start)
      else
        query
      end

    if age_range_end do
      query
      |> where([t], as(:block).timestamp <= ^age_range_end)
    else
      query
    end
  end

  def paginate_query_with_sort_type(query, input, %{cursor_fields: cursor_fields} = params) do
    sort_condtion = Map.get(input, :sort_type)

    if is_nil(sort_condtion) do
      paginate_query(query, input, params)
    else
      new_cursor_fields =
        Enum.map(cursor_fields, fn cf ->
          if is_tuple(cf), do: cf, else: {cf, sort_condtion}
        end)

      params = %{params | cursor_fields: new_cursor_fields}
      paginate_query(query, input, params)
    end
  end

  def paginate_query({:error, _} = error, _, _), do: error

  def paginate_query(
        query,
        input,
        %{
          cursor_fields: cursor_fields,
          total_count_primary_key_field: total_count_primary_key_field
        } = params
      ) do
    limit = input[:limit]

    case {input[:before], input[:after]} do
      {nil, nil} ->
        Repo.graphql_paginate(
          query,
          cursor_fields: cursor_fields,
          total_count_primary_key_field: total_count_primary_key_field,
          limit: limit
        )

      {nil, query_after} ->
        Repo.graphql_paginate(
          query,
          after: query_after,
          cursor_fields: cursor_fields,
          total_count_primary_key_field: total_count_primary_key_field,
          limit: limit
        )

      {query_before, nil} ->
        result =
          Repo.graphql_paginate(
            query,
            before: query_before,
            cursor_fields: cursor_fields,
            total_count_primary_key_field: total_count_primary_key_field,
            limit: limit
          )

        maybe_first_page(result, query, input, params)

      _ ->
        {:error, "before and after both exist"}
    end
  end

  def paginate_query(
        query,
        input,
        %{
          cursor_fields: cursor_fields
        }
      ) do
    paginate_query(
      query,
      input,
      %{
        cursor_fields: cursor_fields,
        total_count_primary_key_field: :id
      }
    )
  end

  def maybe_first_page(first_result, query, input, params) do
    limit = input[:limit]

    if first_result.metadata.total_count < limit do
      input = Map.delete(input, :before)

      paginate_query(
        query,
        input,
        params
      )
    else
      first_result
    end
  end
end
