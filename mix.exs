defmodule GodwokenExplorer.MixProject do
  use Mix.Project

  def project do
    [
      app: :godwoken_explorer,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {GodwokenExplorer.Application, []},
      extra_applications: [:retry, :logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.9"},
      {:phoenix_ecto, "~> 4.3"},
      {:ecto_sql, "~> 3.6.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.14.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:httpoison, "~> 1.8"},
      {:rustler, "~> 0.22.0"},
      {:con_cache, "~> 0.13"},
      {:scrivener_ecto, "~> 2.0"},
      {:decimal, "~> 2.0"},
      {:logger_file_backend, "~> 0.0.10"},
      {:blake2_elixir, "~> 0.8.1"},
      {:fastglobal, "~> 1.0"},

      # live dashboard ecto stats
      {:ecto_psql_extras, "~> 0.6"},

      # admin dashboard
      {:torch, "~> 3.6"},

      # CORS
      {:cors_plug, "~> 2.0"},

      # monitor
      {:observer_cli, "~> 1.6"},
      {:sentry, "~> 8.0"},

      # static code analysis tool
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:sobelow, "~> 0.8", only: :dev},

      # web3 tool
      {:exw3, "~> 0.6"},
      {:ex_abi, "~> 0.5.8"},

      # database_history
      {:ex_audit, "~> 0.9"},

      # jsonapi
      {:jsonapi, "~> 1.3.0"},
      {:poison, "~> 5.0"},

      {:appsignal_phoenix, "~> 2.0"},
      {:appsignal, "~> 2.0"},
      {:retry, "~> 0.15"},

      # test
      {:ex_machina, "~> 2.7.0", only: :test},
      {:excoveralls, "~> 0.10", only: :test},
      {:mock, "~> 0.3.0", only: [:test], runtime: false},
      {:mox, "~> 0.4", only: [:test]},

      # deployment
      {:distillery, "~> 2.1", warn_missing: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
