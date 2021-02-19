defmodule GodwokenRPC.Util do
  def hex_to_number(hex_number) do
     hex_number |> String.slice(2..-1) |> String.to_integer(16)
  end
end
