defmodule Meandro.Ignore do
  @moduledoc """
  Meandro ignore logic
  """

  defstruct [:file, :module, :rule, :pattern]

  @type t :: %Meandro.Ignore{
          file: String.t(),
          module: module,
          rule: module,
          pattern: term
        }

  @spec ignores(Meandro.Rule.asts()) :: any
  def ignores(files_and_asts) do
    for {file, module_asts} <- files_and_asts,
        {module_name, ast} <- module_asts do
      {_, {_, _, ignores}} = Macro.prewalk(ast, {file, module_name, []}, &ignores_in_module/2)
      {file, ignores}
    end
    |> List.foldl(%{}, fn {key, value}, map ->
      Map.update(map, key, value, fn existing_value -> List.flatten([value | existing_value]) end)
    end)
  end

  @spec remove_ignored([Meandro.Rule.t()], any) :: {[Meandro.Rule.t()], non_neg_integer}
  def remove_ignored(results, ignores) do
    remove_ignored(results, ignores, {[], 0})
  end

  defp remove_ignored([], _ignores, {acc, ignored}) do
    {acc, ignored}
  end

  defp remove_ignored([%Meandro.Rule{file: file} = result | results], ignores, {acc, ignored}) do
    ignores_for_file = ignores |> Map.get(file, [])

    if Enum.any?(ignores_for_file, fn ignore -> result_ignored?(result, ignore) end) do
      remove_ignored(results, ignores, {acc, ignored + 1})
    else
      remove_ignored(results, ignores, {[result | acc], ignored})
    end
  end

  defp result_ignored?(
         %Meandro.Rule{file: file, rule: rule, pattern: found_pattern},
         %Meandro.Ignore{
           file: file,
           rule: rule,
           pattern: ignore_pattern
         }
       ) do
    rule.is_ignored?(found_pattern, ignore_pattern)
  end

  defp result_ignored?(_rule, _ignored) do
    false
  end

  defp ignores_in_module(
         {:@, _, [{:meandro, _, [[ignore: {{:__aliases__, _, rule_aliases}, pattern}]]}]} = ast,
         {file, module, ignores}
       ) do
    rule = rule_aliases |> Module.concat()
    ignore = %Meandro.Ignore{file: file, module: module, rule: rule, pattern: pattern}
    {ast, {file, module, [ignore | ignores]}}
  end

  defp ignores_in_module(ast, {file, module, ignores}) do
    {ast, {file, module, ignores}}
  end
end
