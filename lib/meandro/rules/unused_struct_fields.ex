defmodule Meandro.Rule.UnusedStructFields do
  @moduledoc """
  Finds struct fields that are not used.
  It has the following assumptions:
    - As we are not tracking the value of each variable and a variable can be
      reassigned we don't check the struct name when looking for access to a
      struct field or modification
  """

  @behaviour Meandro.Rule

  alias Meandro.Util

  @impl Meandro.Rule
  def analyze(files_and_asts, _options) do
    structs_info = structs_info(files_and_asts)

    unused_structs =
      List.foldl(files_and_asts, structs_info, fn {_file, module_asts}, structs_info ->
        List.foldl(module_asts, structs_info, fn {_module_name, ast}, structs_info ->
          analyze_module(ast, structs_info)
        end)
      end)

    filtered_unused_structs =
      Enum.filter(unused_structs, fn struct_info -> Map.has_key?(struct_info, :fields) end)

    List.foldl(filtered_unused_structs, [], fn %{
                                                 module_name: module_name,
                                                 file: file,
                                                 fields: fields
                                               },
                                               results ->
      List.foldl(fields, results, fn field, results ->
        [
          %Meandro.Rule{
            file: file,
            pattern: {module_name, field},
            text: "The field #{field} from the struct #{module_name} is unused"
          }
          | results
        ]
      end)
    end)
  end

  @impl Meandro.Rule
  def is_ignored?({struct, field}, {struct, field}) do
    true
  end

  def is_ignored?({struct, _field}, struct) do
    true
  end

  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp structs_info(files_and_asts) do
    for {file, module_asts} <- files_and_asts,
        {_module_name, ast} <- module_asts,
        struct_info = struct_info(ast) do
      Map.put_new(struct_info, :file, file)
    end
  end

  defp analyze_module(ast, unused_structs) do
    functions = Meandro.Util.functions(ast)

    fun = fn function, unused_structs ->
      {_, unused_structs} = Macro.prewalk(function, unused_structs, &find_usage_in_ast/2)
      unused_structs
    end

    List.foldl(functions, unused_structs, fun)
  end

  # looking for fields where the struct is initialized
  defp find_usage_in_ast(
         {:%, _, [{:__aliases__, _, aliases}, {:%{}, _, field_list}]} = ast,
         unused_structs
       ) do
    unused_structs =
      for %{module_aliases: struct_aliases, fields: struct_fields} = struct <- unused_structs do
        if struct_aliases == aliases do
          struct_fields =
            for struct_field <- struct_fields, List.keyfind(field_list, struct_field, 0) == nil do
              struct_field
            end

          Map.put(struct, :fields, struct_fields)
        else
          struct
        end
      end

    {ast, unused_structs}
  end

  # looking for fields where the struct is modified
  defp find_usage_in_ast(
         {:%{}, _, [{:|, _, [_, field_list]}]} = ast,
         unused_structs
       ) do
    unused_structs =
      for %{field: struct_fields} <- unused_structs do
        for struct_field <- struct_fields, List.keyfind(field_list, struct_field, 0) == nil do
          struct_field
        end
      end

    {ast, unused_structs}
  end

  # looking for fields where the struct is used
  defp find_usage_in_ast({:., _, [_, field]} = ast, unused_structs) do
    unused_structs =
      for %{field: struct_fields} <- unused_structs do
        List.delete(struct_fields, field)
      end

    {ast, unused_structs}
  end

  defp find_usage_in_ast(other, unused_structs) do
    {other, unused_structs}
  end

  defp struct_info(ast) do
    {_, struct_info} = Macro.prewalk(ast, %{}, &collect_struct_info/2)
    struct_info
  end

  defp collect_struct_info(
         {:defmodule, [line: _], [{:__aliases__, [line: _], aliases}, _other]} = ast,
         struct_info
       ) do
    module_name = Util.ast_module_name_to_atom(aliases)

    struct_info =
      struct_info
      |> Map.put_new(:module_name, module_name)
      |> Map.put_new(:module_aliases, aliases)

    {ast, struct_info}
  end

  defp collect_struct_info({:defstruct, [line: _], [fields]} = ast, struct_info) do
    field_names =
      for field <- fields do
        case field do
          {name, _default} -> name
          name -> name
        end
      end

    {ast, Map.put_new(struct_info, :fields, field_names)}
  end

  defp collect_struct_info(other, module_name) do
    {other, module_name}
  end
end
