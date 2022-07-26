defmodule Meandro.Rule.UnusedCallbacks do
  @moduledoc """
  Finds callbacks that aren't being used in the module where they're defined.

  This rule assumes:
  1. That you always use the callbacks that you define for a behaviour in the
     same module where you define the behaviour.
  2. That you always call the callback functions using dot notation (i.e. `mod.callback(…)`).
     If you use `:erlang.apply(…)` or other method, you'll have to ignore this rule.
  """

  @behaviour Meandro.Rule

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

  defp analyze_file(file, ast) do
    {_, callbacks} = Macro.prewalk(ast, [], &collect_callbacks/2)

    for {name, arity, line} <- callbacks, is_unused(name, arity, ast) do
      %Meandro.Rule{
        file: file,
        line: line,
        text: "Callback #{name}/#{arity} is not used anywhere in the module",
        pattern: {name, arity}
      }
    end
  end

  defp collect_callbacks({:callback, _, _} = callback, acc),
    do: {callback, [parse(callback) | acc]}

  defp collect_callbacks(other, acc), do: {other, acc}

  defp parse({:callback, meta, [{:"::", _, [definition, _result]}]}) do
    line = Keyword.get(meta, :line, 0)
    {name, _, params} = definition
    {name, length(params), line}
  end

  defp is_unused(name, arity, ast) do
    {_, count} = Macro.prewalk(ast, 0, fn node, acc -> count_calls(name, arity, node, acc) end)
    count == 0
  end

  # Standard function application: SOMETHING.name(params) with the right number of params
  defp count_calls(name, arity, {{:., _, [_, name]}, _, params} = node, acc)
       when length(params) == arity,
       do: {node, acc + 1}

  # Function references: &SOMETHING.name/arity
  defp count_calls(
         name,
         arity,
         {:&, _, [{:/, _, [{{:., _, [_, name]}, _, []}, arity]}]} = node,
         acc
       ),
       do: {node, acc + 1}

  # All other nodes
  defp count_calls(_, _, node, acc), do: {node, acc}
end
