[
  import_deps: [:ecto, :phoenix],
  inputs: [
    ".credo.exs",
    ".formatter.exs",
    "mix.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  subdirectories: ["priv/*/migrations"]
]
