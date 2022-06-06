defmodule GodwokenExplorer.Graphql.Types.Custom.BigInt do
  use Absinthe.Schema.Notation

  scalar :bigint do
    description("""
    The `bigint` scalar type represents signed big integer
    values parsed by the elixir `Decimal` library(which support big integer scenario).  The BigInt appears in a JSON
    response as a string to preserve Big Interger.

    Formally:
    sign           ::=  '+' | '-'
    digit          ::=  '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' |
                        '8' | '9'
    digits         ::=  digit [digit]...
    numeric-string ::=  [sign] digits| [sign] digit

    Examples:

    Some numeric strings are:

        "0"          -- zero
        "12"         -- a whole number
        "-76"        -- a signed whole number
    """)

    serialize(&Absinthe.Type.Custom.Decimal.serialize/1)
    parse(&Absinthe.Type.Custom.Decimal.parse/1)
  end
end
