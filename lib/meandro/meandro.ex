defmodule Meandro do
  # @todo add docs and @moduledoc
  @moduledoc """
  Documentation for `Meandro`.
  """

  @doc """
  Analyze
  """
  @spec analyze([Path.t()], [module()], Meandro.Util.parsing_style()) :: %{
          required(:results) => [Meandro.Rule.result()],
          required(:unused_ignores) => [],
          required(:stats) => %{atom() => integer()}
        }
  def analyze(files, rules, parsing_style) do
    files_and_asts = Meandro.Util.parse_files(files, parsing_style)

    results =
      for rule_mod <- rules, do: Meandro.Rule.analyze(rule_mod, files_and_asts, :nocontext)

    %{
      results: results,
      unused_ignores: [],
      stats: %{ignored: 0, parsed: length(files_and_asts), analyzed: length(files_and_asts), total: length(files_and_asts)}
    }
  end
end
