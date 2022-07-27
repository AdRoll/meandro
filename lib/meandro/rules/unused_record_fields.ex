defmodule Meandro.Rule.UnusedRecordFields do
  @moduledoc """
  Finds instances where a record has fields defined that are not being used.

  This rule assumes that your code will never use the underlying tuple
  structure of your records directly.
  """

  alias Meandro.Util

  @behaviour Meandro.Rule

  @impl Meandro.Rule
  def analyze(files_and_asts, _options) do
    for {file, ast} <- files_and_asts,
        result <- analyze_file(file, ast) do
      result
    end
  end

  @impl Meandro.Rule
  def is_ignored?({module, record, fields}, {module, record, fields}) do
    true
  end

  def is_ignored?({_module, record, _fields}, record) do
    true
  end

  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp analyze_file(file, ast) do
    {_, acc} = Macro.prewalk(ast, %{module: nil, records: []}, &collect_record_info/2)

    for {module, name, _num_of_fields, unused_fields, line} <-
          Enum.reverse(acc[:records]),
        unused_fields != [] do
      camel_name = name |> Atom.to_string() |> Macro.camelize()

      %Meandro.Rule{
        file: file,
        line: line,
        text:
          "Record :#{name} (#{camel_name}) has the following unused fields in the module: #{inspect(unused_fields)}",
        pattern: {module, name, unused_fields}
      }
    end
  end

  defp collect_record_info(
         {:defmodule, [line: _], [{:__aliases__, [line: _], aliases}, _other]} = ast,
         acc
       ) do
    module_name = Util.ast_module_name_to_atom(aliases)
    acc = %{acc | module: module_name}
    {ast, acc}
  end

  defp collect_record_info(
         {{:., [line: line], aliases}, _, params} = ast,
         %{module: module, records: records} = acc
       ) do
    case aliases do
      [{:__aliases__, _, [:Record]}, record_def] when record_def in [:defrecord, :defrecordp] ->
        [name, fields] = params
        fields = for {field, _default_value} <- fields, do: field
        record = {module, name, length(fields), fields, line}
        {ast, %{acc | records: [record | records]}}

      _ ->
        # not a record definition
        {ast, acc}
    end
  end

  # E.g.:
  # {:{}, [line: 11], [:priv_record, {:variable, [line: 11], nil}, {:variable, [line: 11], nil}]}
  defp collect_record_info(
         {:{}, [line: _], [maybe_record_name | args]} = ast,
         %{module: module, records: records} = acc
       )
       when is_atom(maybe_record_name) do
    case List.keyfind(records, maybe_record_name, 1, :not_found) do
      :not_found ->
        # it wasn't a record?
        {ast, acc}

      {^module, ^maybe_record_name, num_of_fields, _fields, line}
      when num_of_fields == length(args) ->
        record = {module, maybe_record_name, num_of_fields, [], line}
        new_records = List.keyreplace(records, maybe_record_name, 1, record)
        {ast, %{acc | records: new_records}}

      {^module, ^maybe_record_name, _num_of_fields, _fields, _line} ->
        # this is a record with the same name, but different number of arguments,
        # so an edge-case I don't know how to handle (this would create a different "record" than
        # the one defined we know about)
        {ast, acc}
    end
  end

  # E.g.:
  # {:{}, [line: _],[{:__aliases__, [line: _],[:PrivRecord]},{:variable, [line: _], nil},{:variable, [line: _], nil}]}
  defp collect_record_info(
         {:{}, [line: _], [{:__aliases__, [line: _], [maybe_record_name]} | args]} = ast,
         %{module: module, records: records} = acc
       )
       when is_atom(maybe_record_name) do
    # Atoms like :PrivRecord are different than atoms like PrivRecord.
    # When calling Macro.underscore/1 on the latter, the string "priv_record" will be produced,
    # but when calling the function on the former, it will crash. Those atoms need to be
    # converted to strings (which are produced such as "Elixir.PrivRecord") and then passed
    # to Macro.underscore/1 to obtain the same string as with the latter
    maybe_record_name =
      maybe_record_name
      |> Atom.to_string()
      |> String.trim_leading("Elixir.")
      |> Macro.underscore()
      |> String.to_atom()

    case List.keyfind(records, maybe_record_name, 1, :not_found) do
      :not_found ->
        # it wasn't a record
        {ast, acc}

      {^module, ^maybe_record_name, num_of_fields, _fields, line}
      when num_of_fields == length(args) ->
        record = {module, maybe_record_name, num_of_fields, [], line}
        new_records = List.keyreplace(records, maybe_record_name, 1, record)
        {ast, %{acc | records: new_records}}

      {^module, ^maybe_record_name, _num_of_fields, _fields, _line} ->
        # this is a record with the same name, but different number of arguments,
        # so an edge-case I don't know how to handle (this would create a different "record" than
        # the one defined we know about)
        {ast, acc}
    end
  end

  # E.g.: record_name(record_variable, :record_field)
  defp collect_record_info(
         {record_name, [line: _], [{:record, _, _}, field]} = ast,
         %{records: records} = acc
       )
       when is_atom(record_name) and is_atom(field) do
    {module, ^record_name, num_of_fields, fields, line} = List.keyfind(records, record_name, 1)

    record = {module, record_name, num_of_fields, fields -- [field], line}
    new_records = List.keyreplace(records, record_name, 1, record)
    {ast, %{acc | records: new_records}}
  end

  defp collect_record_info(other, acc) do
    {other, acc}
  end
end
