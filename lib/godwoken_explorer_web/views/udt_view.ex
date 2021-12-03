defmodule GodwokenExplorer.UDTView do
  use JSONAPI.View, type: "udt"

  def fields do
    [:id, :script_hash, :symbol, :decimal]
  end
end
