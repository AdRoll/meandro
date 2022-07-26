defmodule Meandro.Rule.UnusedCallback do
  @moduledoc """
  Finds callbacks that aren't being used
  """

  @behaviour MeandroRule

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

  defp analyze_file(file, _ast) do
    [set_result(file, nil, nil, nil)]
  end

  defp set_result(file, line, callback, arity) do
    %{
      file: file,
      line: line,
      text: "Callback #{callback}/#{arity} is not used anywhere in the module",
      pattern: {callback, arity}
    }
  end
end
