defmodule GodwokenExplorer.Graphql.Resolvers.Common do
  alias GodwokenExplorer.PaginateRepo

  def paginate_query({:error, _} = error, _, _), do: error

  def paginate_query(query, input, %{
        cursor_fields: cursor_fields,
        total_count_primary_key_field: total_count_primary_key_field
      }) do
    limit = input[:limit]

    case {input[:before], input[:after]} do
      {nil, nil} ->
        PaginateRepo.paginate(
          query,
          cursor_fields: cursor_fields,
          total_count_primary_key_field: total_count_primary_key_field,
          limit: limit
        )

      {nil, query_after} ->
        PaginateRepo.paginate(
          query,
          after: query_after,
          cursor_fields: cursor_fields,
          total_count_primary_key_field: total_count_primary_key_field,
          limit: limit
        )

      {query_before, nil} ->
        PaginateRepo.paginate(
          query,
          before: query_before,
          cursor_fields: cursor_fields,
          total_count_primary_key_field: total_count_primary_key_field,
          limit: limit
        )

      _ ->
        {:error, "before and after both exist"}
    end
  end

  def paginate_query(query, input, %{cursor_fields: cursor_fields}) do
    paginate_query(
      query,
      input,
      %{cursor_fields: cursor_fields, total_count_primary_key_field: :id}
    )
  end
end
