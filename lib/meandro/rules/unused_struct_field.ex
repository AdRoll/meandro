defmodule Meandro.Rule.UnusedStructField do
  @moduledoc """
  Finds callbacks that aren't being used
  """

  @behaviour Meandro.Rule

  @impl true
  def analyze(files_and_asts, _options) do
    for {file, ast} <- files_and_asts,
        result <- analyze_file(file, ast, files_and_asts) do
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

  defp analyze_file(_file, ast, files_and_asts) do
    struct_info = struct_info(ast)
    case Map.size(struct_info) do
      0 ->
        []
      _ ->
        fields = Map.get(struct_info, :fields)
        module_name = Map.get(struct_info, :module_name)
        for field <- fields do
          unused = is_unused(field, module_name, files_and_asts)
          IO.puts("The field #{field} from the struct #{module_name}")
          unused
        end
    end
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
    {other, module_name}
  end

  defp is_unused(_field, _module, []) do
    true
  end

  defp is_unused(field, module, [{_file, ast} | tl]) do
    case Macro.prewalk(ast, {true, field, module}, &is_unused_in_ast/2) do
      {_, {true, _, _}} ->
        is_unused(field, module, tl)
      {_, {false, _, _}}  ->
        false
    end
  end

  defp is_unused_in_ast(other, {result, field, module}) do
    {other, {result, field, module}}
  end
end
