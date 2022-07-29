defmodule Meandro.ConfigParser do
  @moduledoc """
  Meandro's `mix.exs` configuration parser (note: it parses, but doesn't validate the data).

  Given a config file (the file defaults to `mix.exs`), this module will try to parse out of
  it the set of rules to analyze with, the parsing style, and the list of ignores.

  More information about these configuration parameters can be found in the README.md
  """

  @typedoc """
  Meandro's final result.
  """

  @rules_wildcard "lib/meandro/rules/*.ex"

  @type ignore :: {Path.t(), Meandro.Rule.t(), list()}
  @type meandro_config() :: [
          rules: [Meandro.Rule.t()],
          parsing: Meandro.Util.parsing_style(),
          ignore: [ignore()]
        ]

  @spec parse_config() :: meandro_config()
  def parse_config(), do: parse_config(Mix.Project.config())

  @spec parse_config(keyword()) :: meandro_config()
  def parse_config(config) do
    meandro_config = config[:meandro] || []

    [
      rules: get_rules(meandro_config[:rules]),
      parsing: get_parsing_style(meandro_config[:parsing]),
      ignore: get_ignores(meandro_config[:ignore])
    ]
  end

  @spec get_rules([Meandro.Rule.t() | nil]) :: [Meandro.Rule.t()]
  defp get_rules(nil), do: default_rules()

  defp get_rules(rules) do
    rule_files()
    |> Enum.filter(fn file ->
      rule =
        file
        |> Path.basename(".ex")
        |> String.to_atom()

      rule in rules
    end)
    |> Enum.map(&Meandro.Util.module_name_from_file_path/1)
  end

  @spec get_parsing_style(Meandro.Util.parsing_style() | nil) :: Meandro.Util.parsing_style()
  defp get_parsing_style(nil), do: :parallel
  defp get_parsing_style(style), do: style

  @spec get_ignores([
          Path.t()
          | {Path.t(), Meandro.Rule.t() | [Meandro.Rule.t()]}
          | {Path.t(), Meandro.Rule.t() | [Meandro.Rule.t()], list()}
        ]) :: [ignore()]
  defp get_ignores(nil), do: []

  defp get_ignores(ignores) do
    for {wildcard, rule, opts} <- normalize_ignores(ignores),
        file <- expand_wildcard(wildcard),
        do: {file, rule, opts}
  end

  # someone used the [keyword: value] when defining the ignore list,
  # which turned the file path into an atom
  defp expand_wildcard(wildcard) when is_atom(wildcard) do
    wildcard
    |> Atom.to_string()
    |> Path.wildcard()
  end

  defp expand_wildcard(wildcard), do: Path.wildcard(wildcard)

  defp normalize_ignores(ignores) do
    Enum.reduce(ignores, [], &normalize_ignores/2)
  end

  defp normalize_ignores(ignore, acc) when is_tuple(ignore),
    do: normalize_ignore_tuple(ignore, acc)

  # @todo update when we add opts to the ignore ruleset
  defp normalize_ignores(ignore, acc), do: [{ignore, :all, []} | acc]

  defp normalize_ignore_tuple({wildcard, rules, opts}, acc) when is_list(rules) do
    normalized = for rule <- rules, do: {wildcard, rule, opts}
    normalized ++ acc
  end

  defp normalize_ignore_tuple({wildcard, rule, opts}, acc), do: [{wildcard, rule, opts} | acc]

  defp normalize_ignore_tuple({wildcard, rules}, acc) when is_list(rules) do
    # @todo update when we add opts to the ignore ruleset
    normalized = for rule <- rules, do: {wildcard, rule, []}
    normalized ++ acc
  end

  defp normalize_ignore_tuple({wildcard, rule}, acc), do: [{wildcard, rule, []} | acc]

  defp default_rules() do
    for file <- rule_files(),
        do: Meandro.Util.module_name_from_file_path(file)
  end

  defp rule_files() do
    __ENV__.file
    |> Path.split()
    |> Enum.slice(0..-4)
    |> Path.join()
    |> Path.join(@rules_wildcard)
    |> Path.wildcard()
  end
end
