defmodule Meandro.Rules.UnusedRecordFields do
  @moduledoc """
  Finds instances where a record has fields defined that are not used
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
  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp analyze_file(_file, ast) do
    record_info(ast)
    |> IO.inspect(label: "analyze file")
  end

  defp record_info(ast) do
    {_, record_info} = Macro.prewalk(ast, %{}, &collect_record_info/2)
    record_info
  end

  defp collect_record_info({:defmodule, [line: _], [{:__aliases__, [line: _], aliases}, _other]} = ast, record_info) do
    IO.inspect(record_info, label: "record info")
    module_name = aliases |> Enum.map(&Atom.to_string/1) |> Enum.join(".") |> String.to_atom()
    record_info = record_info |> Map.put_new(:module_name, module_name)
    {ast, record_info}
  end

  defp collect_record_info({:defrecord, [line: _], [fields]} = ast, record_info) do
    record_info = record_info |> Map.put_new(:fields, fields)
    {ast, record_info}
  end

  defp collect_record_info({:defrecordp, [line: _], [fields]} = ast, record_info) do
    record_info = record_info |> Map.put_new(:fields, fields)
    {ast, record_info}
  end

  defp collect_record_info(other, module_name) do
    IO.inspect(other, label: "other")
    # IO.puts(header)
    {other, module_name}
  end
end
