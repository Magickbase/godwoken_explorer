defmodule GodwokenExplorer.Graphql.Middleware.Downcase do
  @behaviour Absinthe.Middleware

  def call(resolution, config) when is_list(config) do
    arguments = resolution.arguments
    input = arguments[:input]

    if is_nil(input) do
      resolution
    else
      new_input = downcase(input, config)
      %{resolution | arguments: %{arguments | input: new_input}}
    end
  end

  defp downcase(input, config) do
    Enum.reduce(config, input, fn field, acc ->
      case acc[field] do
        acc_field when is_bitstring(acc_field) ->
          Map.put(acc, field, String.downcase(acc_field))

        acc_fields when is_list(acc_fields) ->
          acc_fields =
            Enum.map(acc_fields, fn acc_field ->
              if is_bitstring(acc_field) do
                String.downcase(acc_field)
              else
                acc_field
              end
            end)

          Map.put(acc, field, acc_fields)

        _ ->
          acc
      end
    end)
  end
end
