defmodule Meandro.Rule.UnusedMacros do
  @moduledoc """
  Finds macros that are not used.
  """

  @behaviour Meandro.Rule

  @impl Meandro.Rule
  def analyze(files_and_asts, _options) do
    List.flatten(
      for {file, module_asts} <- files_and_asts,
          {_module_name, ast} <- module_asts,
          result <- analyze_module(file, ast, files_and_asts) do
        result
      end
    )
  end

  @impl Meandro.Rule
  def is_ignored?(module, module) do
    true
  end

  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp analyze_module(file, ast, files_and_asts) do
    module_aliases = Meandro.Util.module_aliases(ast)
    macros = macros(ast, module_aliases)

    for macro_info <- macros do
      unused = is_unused?(macro_info, files_and_asts)
      macro = macro_info |> Map.get(:name)
      line = macro_info |> Map.get(:line)

      if unused do
        %Meandro.Rule{
          file: file,
          rule: __MODULE__,
          line: line,
          text: "The macro #{macro} is unused"
        }
      else
        []
      end
    end
  end

  defp is_unused?(_macro_info, []) do
    true
  end

  defp is_unused?(macro_info, [{_file, ast} | tl]) do
    functions = Meandro.Util.functions(ast)
    macro = macro_info |> Map.get(:name)
    aliases = macro_info |> Map.get(:aliases)

    unused_in_functions =
      for function <- functions do
        case Macro.prewalk(function, {true, {macro, aliases}}, &is_unused_in_ast/2) do
          {_, {true, _}} ->
            is_unused?(macro_info, tl)

          {_, {false, _}} ->
            false
        end
      end

    if Enum.all?(unused_in_functions) do
      is_unused?(macro_info, tl)
    else
      false
    end
  end

  defp is_unused_in_ast(ast, {false, macro_info}) do
    {ast, {false, macro_info}}
  end

  defp is_unused_in_ast({:., _, [{:__aliases__, _, aliases}, macro]} = ast, {_result, {macro, aliases}}) do
    {ast, {false, {macro, aliases}}}
  end

  defp is_unused_in_ast({macro, _, _} = ast, {_result, {macro, aliases}}) do
    {ast, {false, {macro, aliases}}}
  end

  defp is_unused_in_ast(other, {result, {macro, aliases}}) do
    IO.puts("----------NEXT LINE--------")
    IO.inspect(other)
    {other, {result, {macro, aliases}}}
  end

  defp macros(ast, module_aliases) do
    {_, {_module_aliases, macros}} = Macro.prewalk(ast, {module_aliases, %{}}, &collect_macros/2)
    macros
  end

  defp collect_macros({:defmacro, [line: line_num], [{macro_name, _, _}, _]} = ast, {module_aliases, macros}) do
    {ast, {module_aliases, [%{name: macro_name, line: line_num, aliases: module_aliases} | macros]}}
  end

  defp collect_macros(other, {module_aliases, macros}) do
    {other, {module_aliases, macros}}
  end
end
