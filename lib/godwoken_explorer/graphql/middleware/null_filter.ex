defmodule GodwokenExplorer.Graphql.Middleware.NullFilter do
  @behaviour Absinthe.Middleware

  def call(resolution, _config) do
    arguments = resolution.arguments
    input = arguments[:input]

    if is_nil(input) do
      resolution
    else
      new_input = null_filtering(input)
      %{resolution | arguments: %{arguments | input: new_input}}
    end
  end

  defp null_filtering(input) do
    Enum.reduce(input, input, fn {key, v}, acc ->
      case v do
        nil ->
          Map.drop(acc, [key])

        _ ->
          acc
      end
    end)
  end
end
