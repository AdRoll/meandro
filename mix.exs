defmodule Meandro.MixProject do
  use Mix.Project

  def project do
    [
      app: :meandro,
      description: "The Elixir dead code cleaner",
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      main: "Mix.Tasks.Meandro",
      dialyzer: [
        flags: [:no_return, :unmatched_returns, :error_handling, :underspecs],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
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
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false}
    ]
  end
end
