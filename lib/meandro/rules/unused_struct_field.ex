defmodule Meandro.Rule.UnusedStructFields do
  @moduledoc """
  Finds struct fields that are not used.
  It has the following assumptions:
    - As we are not tracking the value of each variable and a variable can be
      reassigned we don't check the struct name when looking for access to a
      struct field or modification
  """

  alias Meandro.Util

  @behaviour Meandro.Rule

  @impl Meandro.Rule
  def analyze(files_and_asts, _options) do
    for {file, module_asts} <- files_and_asts,
        {_module_name, ast} <- module_asts,
        result <- analyze_module(file, ast, files_and_asts) do
      result
    end
    |> List.flatten()
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

  defp analyze_module(file, ast, files_and_asts) do
    struct_info = struct_info(ast)

    case Map.get(struct_info, :fields) do
      nil ->
        []

      fields ->
        module_name = struct_info[:module_name]
        module_aliases = struct_info[:module_aliases]

        for field <- fields do
          unused = is_unused?({field, module_name, module_aliases}, files_and_asts)

          case unused do
            true ->
              %Meandro.Rule{
                file: file,
                rule: __MODULE__,
                pattern: {module_name, field},
                text: "The field #{field} from the struct #{module_name} is unused"
              }

            false ->
              []
          end
        end
    end
  end

  defp is_unused?({_field, _module, _aliases}, []) do
    true
  end

  defp is_unused?({field, module, aliases}, [{_file, ast} | tl]) do
    functions = Meandro.Util.functions(ast)

    unused_in_functions =
      for function <- functions do
        case Macro.prewalk(function, {true, {field, module, aliases}}, &is_unused_in_ast/2) do
          {_, {true, _}} ->
            is_unused?({field, module, aliases}, tl)

          {_, {false, _}} ->
            false
        end
      end

    if Enum.all?(unused_in_functions) do
      is_unused?({field, module, aliases}, tl)
    else
      false
    end
  end

  # looking for fields where the struct is initialized
  defp is_unused_in_ast(
         {:%, _, [{:__aliases__, _, aliases}, {:%{}, _, field_list}]} = ast,
         {result, {field, module, aliases}}
       ) do
    result =
      case List.keyfind(field_list, field, 0) do
        nil -> result
        _ -> false
      end

    {ast, {result, {field, module, aliases}}}
  end

  # looking for fields where the struct is modified
  defp is_unused_in_ast(
         {:%{}, _, [{:|, _, [_, field_list]}]} = ast,
         {result, {field, module, aliases}}
       ) do
    result =
      case List.keyfind(field_list, field, 0) do
        nil -> result
        _ -> false
      end

    {ast, {result, {field, module, aliases}}}
  end

  # looking for fields where the struct is used
  defp is_unused_in_ast({:., _, [_, field]} = ast, {_result, {field, module, aliases}}) do
    {ast, {false, {field, module, aliases}}}
  end

  defp is_unused_in_ast(other, {result, {field, module, aliases}}) do
    {other, {result, {field, module, aliases}}}
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
    struct_info = struct_info |> Map.put_new(:fields, fields)
    {ast, struct_info}
  end

  defp collect_struct_info(other, module_name) do
    {other, module_name}
  end
end
