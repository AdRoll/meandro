defmodule Meandro.Rule.UnusedMacros do
  @moduledoc """
  Finds macros that are not used.
  """

  @behaviour Meandro.Rule

  @impl true
  def analyze(files_and_asts, _options) do
    List.flatten(
      for {file, ast} <- files_and_asts,
          result <- analyze_module(file, ast, files_and_asts) do
        result
      end
    )
  end

  @impl true
  def is_ignored?(module, module) do
    true
  end

  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp analyze_module(file, ast, files_and_asts) do
    macros = macros(ast)

    for macro <- macros do
      unused = is_unused?(macro, files_and_asts)
      if unused do
        %Meandro.Rule{
          file: file,
          rule: __MODULE__,
          text: "The macro #{macro |> get(:macro_name)} is unused"
        }
      else
        []
      end
    end
  end

  defp is_unused?({_field, _module, _aliases}, []) do
    true
  end

  defp is_unused?(macro_info, [{_file, ast} | tl]) do
    functions = Meandro.Util.functions(ast)

    unused_in_functions =
      for function <- functions do
        case Macro.prewalk(function, {true, macro_info}, &is_unused_in_ast/2) do
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

  defp is_unused_in_ast(other, {result, {field, module, aliases}}) do
    {other, {result, {field, module, aliases}}}
  end

  defp macros(ast) do
    {_, macros} = Macro.prewalk(ast, %{}, &collect_macros_info/2)
    macros
  end

  defp collect_macros_info(other, module_name) do
    IO.inspect(other)
    IO.puts("------------NEXT LINE-----------")
    {other, module_name}
  end
end
