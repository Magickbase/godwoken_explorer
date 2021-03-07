defmodule GodwokenRPC.Util do
  def hex_to_number(hex_number) do
     hex_number |> String.slice(2..-1) |> String.to_integer(16)
  end

  def number_to_hex(number) do
    "0x" <> (number |> Integer.to_string(16) |> String.downcase())
  end
end
