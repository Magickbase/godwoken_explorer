[
  import_deps: [:ecto, :phoenix],
  inputs: [
    ".credo.exs",
    ".formatter.exs",
    "mix.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  subdirectories: ["priv/*/migrations"]
]
