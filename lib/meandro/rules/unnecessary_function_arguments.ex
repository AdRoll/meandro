defmodule Meandro.Rule.UnnecessaryFunctionArguments do
  @moduledoc """
  Finds function arguments that are consistently ignored in all clauses of a function.

  This rule assumes that:
  1. You don't use variables starting with `_` (i.e. you always ignore those).
  2. You tag all the methods that implement behaviour callbacks with @impl
  """

  @behaviour Meandro.Rule

  @impl Meandro.Rule
  def analyze(files_and_asts, _options) do
    for {file, ast} <- files_and_asts,
        result <- analyze_file(file, ast) do
      result
    end
  end

  @impl Meandro.Rule
  def is_ignored?({function, arity, position}, {function, arity, position}) do
    true
  end

  def is_ignored?({function, arity, _position}, {function, arity}) do
    true
  end

  def is_ignored?({function, _arity, _position}, function) do
    false
  end

  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp analyze_file(file, ast) do
    {_, acc} = Macro.prewalk(ast, %{current_module: nil, functions: %{}}, &collect_functions/2)
    %{functions: functions} = acc

    for {module, function, arity, position, line} <- unnecessary_arguments(functions) do
      %Meandro.Rule{
        file: file,
        line: line,
        text:
          "Argument in position #{position} of #{module}.#{function}/#{arity} is ignored in all of its clauses",
        pattern: {function, arity, position}
      }
    end
  end

  # When we find a module definition we write it down, so we can pair it with the callback definition
  defp collect_functions(
         {:defmodule, [line: _], [{:__aliases__, [line: _], aliases}, _other]} = ast,
         acc
       ) do
    module_name = aliases |> Enum.map_join(".", &Atom.to_string/1) |> String.to_atom()

    {ast, %{acc | current_module: module_name}}
  end

  defp collect_functions({def, meta, [params | _]} = node, acc)
       when params != nil and (def == :def or def == :defp) do
    {name, _meta, arguments} =
      case params do
        {:when, _, [actual_params | _]} ->
          actual_params

        params ->
          params
      end

    %{current_module: module, functions: functions} = acc

    arg_patterns = extract_arg_patterns(arguments)
    key = {module, name, length(arg_patterns)}
    clause = {meta[:line], arg_patterns}

    new_functions =
      Map.update(
        functions,
        key,
        [clause],
        &[clause | &1]
      )

    {node, %{acc | functions: new_functions}}
  end

  defp collect_functions(node, acc) do
    {node, acc}
  end

  defp extract_arg_patterns(nil), do: []

  defp extract_arg_patterns(arguments) do
    for arg <- arguments do
      case arg do
        {pattern, _, _} -> pattern
        _other -> :a_pattern
      end
    end
  end

  defp unnecessary_arguments(functions) do
    for {{module, function, arity}, clauses} <- functions,
        {line, position} <- unnecessary_arguments(arity, clauses) do
      {module, function, arity, position, line}
    end
  end

  defp unnecessary_arguments(arity, clauses) do
    # It's actually the first one since we constructed this list using cons on a prewalk
    {line, _} = List.last(clauses)
    for position <- 1..arity, is_ignored_in_all_clauses?(position, clauses), do: {line, position}
  end

  defp is_ignored_in_all_clauses?(position, clauses) do
    Enum.all?(clauses, fn {_, arg_patterns} ->
      Enum.at(arg_patterns, position - 1) |> is_ignored?
    end)
  end

  defp is_ignored?(:_), do: true

  defp is_ignored?(atom) when is_atom(atom) do
    case Atom.to_string(atom) do
      "_" <> _ -> true
      _ -> false
    end
  end

  defp is_ignored?(_), do: false
end
