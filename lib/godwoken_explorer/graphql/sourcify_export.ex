defmodule GodwokenExplorer.Graphql.SourcifyExport do
  alias GodwokenExplorer.Graphql.Sourcify

  def get_metadata(address_hash_string) do
    get_metadata_full_url = Sourcify.get_metadata_url() <> "/" <> address_hash_string
    Sourcify.http_get_request(get_metadata_full_url, [])
  end
end
