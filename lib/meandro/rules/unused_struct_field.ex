defmodule Meandro.Rule.UnusedStructField do
  @moduledoc """
  Finds callbacks that aren't being used
  """

  @behaviour MeandroRule

  @impl true
  def analyze(files_and_asts, _options) do
    for {file, ast} <- files_and_asts,
        result <- analyze_file(file, ast) do
      result
    end
  end

  @impl true
  def is_ignored?({callback, arity}, {callback, arity}) do
    true
  end

  def is_ignored?({callback, _arity}, callback) do
    true
  end

  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp analyze_file(_file, ast) do
    struct_info = struct_info(ast)
    IO.inspect(struct_info)
  end

  defp set_result(file, line, callback, arity) do
    %{
      file: file,
      line: line,
      text: "Callback #{callback}/#{arity} is not used anywhere in the module",
      pattern: {callback, arity}
    }
  end

  defp struct_info(ast) do
    {_, struct_info} = Macro.prewalk(ast, %{}, &collect_struct_info/2)
    struct_info
  end

  defp collect_struct_info(
         {:defmodule, [line: _], [{:__aliases__, [line: _], aliases}, _other]} = ast,
         struct_info
       ) do
    module_name = aliases |> Enum.map(&Atom.to_string/1) |> Enum.join(".") |> String.to_atom()
    struct_info = struct_info |> Map.put_new(:module_name, module_name)
    {ast, struct_info}
  end

  defp collect_struct_info({:defstruct, [line: _], [fields]} = ast, struct_info) do
    struct_info = struct_info |> Map.put_new(:fields, fields)
    {ast, struct_info}
  end

  defp collect_struct_info(other, module_name) do
    IO.inspect(other)
    {other, module_name}
  end
end
