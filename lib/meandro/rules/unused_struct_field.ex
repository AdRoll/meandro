defmodule Meandro.Rule.UnusedStructField do
  @moduledoc """
  Finds callbacks that aren't being used
  """

  @behaviour Meandro.Rule

  @impl true
  def analyze(files_and_asts, _options) do
    IO.inspect(for {file, ast} <- files_and_asts,
        result <- analyze_module(file, ast, files_and_asts) do
      result
    end)

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

  defp analyze_module(file, ast, files_and_asts) do
    struct_info = struct_info(ast)
    case Kernel.map_size(struct_info) do
      0 ->
        []
      _ ->
        fields = Map.get(struct_info, :fields)
        module_name = Map.get(struct_info, :module_name)
        module_aliases = Map.get(struct_info, :module_aliases)
        List.flatten(for field <- fields do
          unused = is_unused({field, module_name, module_aliases}, files_and_asts)
          case unused do
            true ->
              %Meandro.Rule{file: file, rule: __MODULE__, text: "The field #{field} from the struct #{module_name} is unused"}
            false ->
              []
          end
        end)
    end
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
    struct_info = struct_info |> Map.put_new(:module_name, module_name) |> Map.put_new(:module_aliases, aliases)
    {ast, struct_info}
  end

  defp collect_struct_info({:defstruct, [line: _], [fields]} = ast, struct_info) do
    struct_info = struct_info |> Map.put_new(:fields, fields)
    {ast, struct_info}
  end

  defp collect_struct_info(other, module_name) do
    {other, module_name}
  end

  defp is_unused({_field, _module, _aliases}, []) do
    true
  end

  defp is_unused({field, module, aliases}, [{_file, ast} | tl]) do
    functions = Meandro.Util.functions(ast)
    unused_in_functions = for function <- functions do
      case Macro.prewalk(function, {true, {field, module, aliases}}, &is_unused_in_ast/2) do
        {_, {true, _}} ->
          is_unused({field, module, aliases}, tl)
        {_, {false, _}}  ->
          false
      end
    end
    unused = Enum.all?(unused_in_functions)
    case unused do
      true ->
        is_unused({field, module, aliases}, tl)
      false  ->
        false
    end
  end

  # looking for fields when the struct is initialized
  defp is_unused_in_ast({:%, _, [{:__aliases__, _, aliases},{:%{}, _, field_list}]} = ast, {result, {field, module, aliases}}) do
    result = case List.keyfind(field_list, field, 0, nil) do
      nil -> result
      _ -> false
    end
    {ast, {result, {field, module, aliases}}}
  end

  # looking for fields when the struct is modified
  defp is_unused_in_ast({:%{}, _, [{:|, _, [_, field_list]}]} = ast, {result, {field, module, aliases}}) do
    result = case List.keyfind(field_list, field, 0, nil) do
      nil -> result
      _ -> false
    end
    {ast, {result, {field, module, aliases}}}
  end

  # looking for fields when the struct is used
  defp is_unused_in_ast({:., _, [_, field]} = ast, {_result, {field, module, aliases}}) do
    {ast, {false, {field, module, aliases}}}
  end

  defp is_unused_in_ast(other, {result, {field, module, aliases}}) do
    # IO.inspect(other)
    # IO.puts("-----------NEXT_LINE---------------")
    {other, {result, {field, module, aliases}}}
  end


end
