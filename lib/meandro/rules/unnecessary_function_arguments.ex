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
    for {file, asts} <- files_and_asts,
        {mod, ast} <- asts,
        result <- analyze_file(file, mod, ast) do
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

  defp analyze_file(file, module, ast) do
    {_, acc} = Macro.prewalk(ast, %{is_impl?: false, functions: %{}}, &collect_functions/2)
    %{functions: functions} = acc

    for {function, arity, position, line} <- unnecessary_arguments(functions) do
      %Meandro.Rule{
        module: module,
        file: file,
        line: line,
        text:
          "Argument in position #{position} of #{module}.#{function}/#{arity} is ignored in all of its clauses",
        pattern: {function, arity, position}
      }
    end
  end

  # We track @impl… attributes to avoid analyzing behaviour callbacks.
  # You can't remove parameters from them.
  defp collect_functions({:impl, _, _} = node, acc) do
    {node, %{acc | is_impl?: true}}
  end

  # If the function appears below an @impl … line, we don't check it.
  # It's a behaviour callback. You can't remove parameters from it.
  defp collect_functions({:def, _, _} = node, %{is_impl?: true} = acc) do
    {node, %{acc | is_impl?: false}}
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

    %{functions: functions} = acc

    arg_patterns = extract_arg_patterns(arguments)
    key = {name, length(arg_patterns)}
    clause = {meta[:line], arg_patterns}

    new_functions =
      Map.update(
        functions,
        key,
        [clause],
        &[clause | &1]
      )

    {node, %{acc | is_impl?: false, functions: new_functions}}
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
    for {{function, arity}, clauses} <- functions,
        {line, position} <- unnecessary_arguments(arity, clauses) do
      {function, arity, position, line}
    end
  end

  defp unnecessary_arguments(arity, clauses) do
    # It's actually the first one since we constructed this list using cons on a prewalk
    {line, _} = List.last(clauses)
    for position <- 1..arity, is_ignored_in_all_clauses?(position, clauses), do: {line, position}
  end

  defp is_ignored_in_all_clauses?(position, clauses) do
    Enum.all?(clauses, fn {_, arg_patterns} ->
      arg_patterns |> Enum.at(position - 1) |> is_ignored?
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
