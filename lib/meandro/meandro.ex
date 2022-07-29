defmodule Meandro do
  @moduledoc """
  The Elixir Dead Code Cleaner
  """

  @typedoc """
  Meandro's final result.
  """
  @type result() :: %{
          results: [Meandro.Rule.result()],
          unused_ignores: [],
          stats: %{atom() => integer()}
        }

  @doc """
  Runs a list of rules over a list of files and returns all the dead code pieces it can find.
  """
  @spec analyze([Path.t()], [module()], Meandro.Util.parsing_style()) :: result()
  def analyze(files, rules, parsing_style) do
    files_and_asts = Meandro.Util.parse_files(files, parsing_style)
    ignores = Meandro.Ignore.ignores(files_and_asts)

    results =
      Enum.reduce(rules, [], fn rule_mod, acc ->
        Meandro.Rule.analyze(rule_mod, files_and_asts, :nocontext) ++ acc
      end)

    {results_after_ignores, ignored} = Meandro.Ignore.remove_ignored(results, ignores)

    %{
      results: results_after_ignores,
      unused_ignores: [],
      stats: %{
        ignored: ignored,
        parsed: length(files_and_asts),
        analyzed: length(files_and_asts),
        total: length(files_and_asts)
      }
    }
  end
end
