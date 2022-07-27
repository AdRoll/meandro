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

  def is_ignored?({function, arity, position}, function) do
    false
  end

  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp analyze_file(file, ast) do
    []
  end
end
