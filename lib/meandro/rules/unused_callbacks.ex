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
    {_, acc} = Macro.prewalk(ast, %{current_module: nil, callbacks: []}, &collect_callbacks/2)
    %{callbacks: callbacks} = acc

    for {module, name, arity, line, count} <- callbacks, count == 0 do
      %Meandro.Rule{
        file: file,
        line: line,
        text: "Callback #{module}:#{name}/#{arity} is not used anywhere in the module",
        pattern: {name, arity}
      }
    end
  end

  # When we find a module definition we write it down, so we can pair it with the callback definition
  defp collect_callbacks(
         {:defmodule, [line: _], [{:__aliases__, [line: _], aliases}, _other]} = ast,
         acc
       ) do
    module_name = aliases |> Enum.map(&Atom.to_string/1) |> Enum.join(".") |> String.to_atom()

    {ast, %{acc | current_module: module_name}}
  end

  # When we find a callback, we write it down together with the module it was found on.
  # We also count the number of times a module:callback/arity has been found whilst traversing
  # the AST.
  defp collect_callbacks(
         {:callback, _, _} = callback,
         %{current_module: module, callbacks: callbacks} = acc
       ) do
    {name, arity, line} = parse(callback)

    {callback, %{acc | callbacks: [{module, name, arity, line, 0} | callbacks]}}
  end

  # Standard function application: SOMETHING.name(params) with the right number of params
  defp collect_callbacks({{:., _, [_, name]}, _, params} = node, acc) do
    {node, maybe_update_callback_count(acc, name, _arity = length(params))}
  end

  # Function references: &SOMETHING.name/arity
  defp collect_callbacks(
         {:&, _, [{:/, _, [{{:., _, [_, name]}, _, []}, arity]}]} = node,
         acc
       ) do
    {node, maybe_update_callback_count(acc, name, arity)}
  end

  defp collect_callbacks(other, acc), do: {other, acc}

  defp maybe_update_callback_count(
         %{callbacks: callbacks, current_module: module} = acc,
         name,
         arity
       ) do
    callbacks =
      Enum.map(callbacks, fn
        {^module, ^name, ^arity, line, count} -> {module, name, arity, line, count + 1}
        e -> e
      end)

    %{acc | callbacks: callbacks}
  end

  defp parse({:callback, meta, [{:"::", _, [definition, _result]}]}) do
    line = meta[:line]
    {name, _meta, params} = definition

    unless is_nil(params) do
      {name, length(params), line}
    else
      {name, 0, line}
    end
  end
end
