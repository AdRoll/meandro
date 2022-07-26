defmodule Meandro.Rule.UnusedCallbacks do
  @moduledoc """
  Finds callbacks that aren't being used in the module where they're defined.

  This rule assumes:
  1. That you always use the callbacks that you define for a behaviour in the
     same module where you define the behaviour.
  2. That you always call the callback functions using dot notation (i.e. `mod.callback(…)`).
     If you use `apply(…)` or other method, you'll have to ignore this rule.
  """

  @behaviour Meandro.Rule

  alias Meandro.Util

  @impl Meandro.Rule
  def analyze(files_and_asts, _options) do
    for {file, module_asts} <- files_and_asts,
        {_module_name, ast} <- module_asts,
        result <- analyze_module(file, ast) do
      result
    end
  end

  @impl Meandro.Rule
  def is_ignored?({callback, arity}, {callback, arity}) do
    true
  end

  def is_ignored?({callback, _arity}, callback) do
    true
  end

  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp analyze_module(file, ast) do
    {_, acc} = Macro.prewalk(ast, %{module: nil, callbacks: []}, &collect_callbacks/2)
    %{callbacks: callbacks} = acc

    for {module, name, arity, line, count} <- Enum.reverse(callbacks), count == 0 do
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
         {:defmodule, _, [{:__aliases__, _, aliases}, _]} = ast,
         acc
       ) do
    module_name = Util.ast_module_name_to_atom(aliases)

    {ast, %{acc | module: module_name}}
  end

  # When we find a callback, we write it down together with the module it was found on.
  # We also count the number of times a module:callback/arity has been found whilst traversing
  # the AST.
  # We need to keep track of the current module as well, to avoid nested modules messing up
  # our assumptions.
  defp collect_callbacks(
         # Pattern [{:"::", _, _}] defines callbacks in AST. Using that to avoid wrong match
         # againts a var called "callbacks"
         {:callback, _, [{:"::", _, _}]} = callback,
         %{module: module, callbacks: callbacks} = acc
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
         %{callbacks: callbacks, module: module} = acc,
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

    if is_nil(params) do
      {name, 0, line}
    else
      {name, length(params), line}
    end
  end
end
