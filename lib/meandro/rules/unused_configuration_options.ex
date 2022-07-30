defmodule Meandro.Rule.UnusedConfigurationOptions do
  @moduledoc """
  A rule to detect unused configuration options
  It will find all the config options that are no longer used around the code.

  To avoid this warning, remove the unused parameters.

  ## Some considerations

  - This rule assumes that configuration options for an application are only consumed
  within said application or the other applications in the same umbrella project.
  - If any instance of `Application.get_all_env/1` is detected, this rule will assume
  that all the config options are used.
  """

  @behaviour Meandro.Rule

  @usage_functions [:get_env, :fetch_env, :fetch_env!]

  @impl Meandro.Rule
  def analyze(files_and_asts, context) do
    with app_name <- Keyword.get(context, :app),
         true <- is_atom(app_name),
         mix_env <- Keyword.get(context, :mix_env),
         asts <- aggregate_all_files_asts(files_and_asts) do
      analyze_asts(asts, app_name, mix_env)
    else
      _ ->
        []
    end
  end

  @impl Meandro.Rule
  def is_ignored?(option, option) do
    true
  end

  def is_ignored?(_, _) do
    false
  end

  defp aggregate_all_files_asts(files_and_asts) do
    for {_file, module_asts} <- files_and_asts,
        {_module_name, ast} <- module_asts do
      ast
    end
  end

  defp analyze_asts(asts, app_name, mix_env) do
    options_set =
      app_name
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.sort()
      |> maybe_aggregate_options(app_name)

    usage_map =
      Enum.reduce(asts, %{get_all_env: false, used_options: MapSet.new()}, fn ast, acc ->
        analyze_ast(ast, acc, app_name)
      end)

    for config_option <- options_set -- MapSet.to_list(usage_map.used_options),
        usage_map.get_all_env == false do
      %Meandro.Rule{
        text:
          "Configuration option #{inspect(config_option)} (MIX_ENV=#{mix_env}) is not used anywhere in the code",
        pattern: config_option
      }
    end
  end

  # This covers cases where using the macro config/3
  # config(root_key, key, opts) so, `options` here is a root_key
  defp maybe_aggregate_options(options, app_name) do
    Enum.reduce(options, [], fn option, acc ->
      key = Application.get_env(app_name, option)

      case Keyword.keyword?(key) do
        true ->
          [Keyword.keys(key) | acc] |> List.flatten()

        false ->
          [option | acc]
      end
    end)
  end

  defp analyze_ast(ast, acc0, app_name) do
    {_, usage_map} =
      Macro.prewalk(ast, acc0, fn node, acc ->
        collect_usages(node, acc, app_name)
      end)

    usage_map
  end

  defp collect_usages(
         {{:., _, [{:__aliases__, _, [:Application]}, :get_all_env]}, _, [app_name]},
         acc,
         app_name
       ) do
    # breaks the prewalk sending empty ast
    {{}, %{acc | get_all_env: true}}
  end

  defp collect_usages(
         {{:., _, [{:__aliases__, _, [:Application]}, function]}, _, [app_name, args]} = node,
         acc,
         app_name
       ) do
    config_option = extract_config_option(args)

    case Enum.member?(@usage_functions, function) do
      true ->
        {node, Map.update!(acc, :used_options, &MapSet.put(&1, config_option))}

      false ->
        {node, acc}
    end
  end

  defp collect_usages(node, acc, _app_name) do
    {node, acc}
  end

  defp extract_config_option({option, _, _}), do: option
  defp extract_config_option({option, _}), do: option
  defp extract_config_option(option), do: option
end
