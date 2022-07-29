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
  @spec analyze([Path.t()], [Meandro.Rule.t()], Meandro.Util.parsing_style(), [
          Meandro.ConfigParser.ignore()
        ]) :: result()
  def analyze(files, rules, parsing_style, ignores) do
    ignores_from_config =
      for {file, rule_ignored, _opts} <- ignores,
          rule <- rules,
          rule_ignored == :all or rule_ignored == rule,
          do: {file, rule}

    files_ignored_from_config = for {file, :all} <- ignores_from_config, do: file
    # @todo add @meandro attributes to the final list, before calling usort
    wholly_ignored_files = :lists.usort(files_ignored_from_config)

    files_and_asts =
      files
      |> Enum.reject(fn file -> file in wholly_ignored_files end)
      |> Meandro.Util.parse_files(parsing_style)

    # @todo add @meandro attributes to the final list
    all_ignores = ignores_from_config

    {results, ignored_results} =
      rules
      |> Enum.reduce([], fn rule_mod, acc ->
        Meandro.Rule.analyze(rule_mod, files_and_asts, :nocontext) ++ acc
      end)
      |> remove_ignored_results(all_ignores)

    %{
      results: results,
      unused_ignores: [],
      stats: %{
        ignored: length(ignored_results),
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
