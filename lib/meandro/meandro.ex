defmodule Meandro do
  # @todo add docs and @moduledoc
  @moduledoc """
  Documentation for `Meandro`.
  """

  # the IO.read/2 option changed from :all to :eof in Elixir 1.13
  # so Dialyzer doesn't like the old backwards compatibility mode in 1.13+
  @dialyzer {:no_fail_call, {:parse_files, 2}}

  @type parsing_style() :: :sequential | :parallel

  @doc """
  Analyze
  """
  @spec analyze([Path.t()], [module()], parsing_style()) :: %{
          required(:results) => [Meandro.Rule.result()],
          required(:unused_ignores) => [Meandro.Rule.ignore_spec()],
          required(:stats) => %{atom() => integer()}
        }
  def analyze(files, rules, parsing_style) do
    files_and_asts = parse_files(files, parsing_style)

    results =
      for rule_mod <- rules, do: Meandro.Rule.analyze(rule_mod, files_and_asts, :nocontext)

    %{
      results: results,
      unused_ignores: [],
      stats: %{ignored: nil, parsing: nil, analyzing: nil, total: nil}
    }
  end

  @spec parse_files([Path.t()], parsing_style()) :: [
          {Path.t(), Macro.t()}
        ]
  defp parse_files(paths, :sequential) do
    Enum.map(paths, fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)
      ast = Code.string_to_quoted!(c, token_metadata: true)
      {p, ast}
    end)
  end

  defp parse_files(paths, :parallel) do
    fun = fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)
      ast = Code.string_to_quoted!(c, token_metadata: true)
      {p, ast}
    end

    paths
    |> Enum.map(&Task.async(fn -> fun.(&1) end))
    |> Enum.map(&Task.await/1)
  end
end
