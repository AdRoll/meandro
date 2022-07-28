defmodule Meandro.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :meandro,
      description: "The Elixir dead code cleaner",
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      main: "Mix.Tasks.Meandro",
      dialyzer: [
        flags: [:no_return, :unmatched_returns, :error_handling, :underspecs],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      aliases: aliases(),
      docs: docs(),
      preferred_cli_env: [test_all: :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:mix, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.2", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:ex_doc, "~> 0.28.4", only: :dev, runtime: false}
    ]
  end

  defp aliases() do
    [
      all: ["format --check-formatted", "dialyzer", "credo --strict"],
      test_all: ["test --trace --cover", "test.coverage"]
    ]
  end

  defp docs() do
    [
      extras: [
        LICENSE: [title: "License"],
        "README.md": [title: "Readme"]
      ],
      api_reference: false,
      main: "Mix.Tasks.Meandro",
      source_ref: @version
    ]
  end
end
