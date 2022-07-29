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
  @spec analyze([Path.t()], [Meandro.Rule.t()], keyword(), [
          Meandro.ConfigParser.ignore()
        ]) :: result()
  def analyze(files, rules, context, ignores) do
    parsing_style = Keyword.get(context, :parsing_style, :parallel)

    ignores_from_config =
      for {file, rule_ignored, _opts} <- ignores,
          rule <- rules,
          rule_ignored == :all or rule_ignored == rule,
          do: {file, rule}

    files_and_asts = Meandro.Util.parse_files(files, parsing_style)
    files_ignored_from_config = for {file, :all} <- ignores_from_config, do: file
    ignores_map = Meandro.Ignore.ignores(files_and_asts)

    ignores_from_ast =
      ignores_map
      |> Map.to_list()

    files_ignored_from_ast =
      Enum.filter(ignores_from_ast, fn {_file, value} -> value == :ignore end)

    # @todo handle these in Meandro.Ignore
    _wholly_ignored_files = :lists.usort(files_ignored_from_config ++ files_ignored_from_ast)

    all_ignores = ignores_from_config ++ ignores_from_ast

    {results, ignored_results} =
      rules
      |> Enum.reduce([], fn rule_mod, acc ->
        Meandro.Rule.analyze(rule_mod, files_and_asts, context) ++ acc
      end)
      |> remove_ignored_results(all_ignores)

    {results_after_ignores, ignored} = Meandro.Ignore.remove_ignored(results, ignores)

    %{
      results: results_after_ignores,
      unused_ignores: [],
      stats: %{
        ignored: length(ignored_results) + ignored,
        parsed: length(files_and_asts),
        analyzed: length(files_and_asts),
        total: length(files_and_asts)
      }
    }
  end

  defp remove_ignored_results(results, ignores),
    do: remove_ignored_results(results, ignores, {[], []})

  defp remove_ignored_results([], _ignores, {filtered_results, ignored_results}),
    do: {Enum.reverse(filtered_results), ignored_results}

  defp remove_ignored_results([result | results], ignores, {filtered_results, ignored_results}) do
    remove_ignored_results(results, ignores, {[result | filtered_results], ignored_results})
  end
end
