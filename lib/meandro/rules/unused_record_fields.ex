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
    for {file, module_asts} <- files_and_asts,
        {_module_name, ast} <- module_asts,
        result <- analyze_module(file, ast, files_and_asts) do
      result
    end
    |> List.flatten()
  end

  @impl Meandro.Rule
  def is_ignored?({record, fields}, {record, fields}) do
    true
  end

  def is_ignored?({record, _fields}, record) do
    true
  end

  def is_ignored?(_pattern, _ignore_spec) do
    false
  end

  defp analyze_module(file, ast, files_and_asts) do
    {_, acc} = Macro.prewalk(ast, %{current_module: nil, records: []}, &collect_record_info/2)

    for {module, name, scope, _num_fields, unused_fields, line} = record <-
          Enum.reverse(acc[:records]),
        unused_field <- unused_fields,
        unused_fields != [] do
      camel_name = name |> Atom.to_string() |> Macro.camelize()

      cond do
        scope == :private ->
          # we don't need to check the other files because it's private
          %Meandro.Rule{
            file: file,
            line: line,
            module: module,
            text:
              "Private record :#{name} (#{camel_name}) has an unused field in the module: #{unused_field}",
            pattern: {name, unused_field}
          }

        is_unused?(record, files_and_asts) ->
          %Meandro.Rule{
            file: file,
            line: line,
            module: module,
            text:
              "Public record :#{name} (#{camel_name}) has an unused field in the module: #{unused_field}",
            pattern: {name, unused_field}
          }
      end
    end
  end

  defp is_unused?(_record, []), do: true

  defp is_unused?(record, [{_file, ast} | _tl]) do
    {_, acc} =
      Macro.prewalk(ast, %{current_module: nil, records: [record]}, &count_record_usage/2)

    acc
  end

  defp count_record_usage(ast, acc) do
    {ast, acc}
  end

  defp collect_record_info(
         {:defmodule, [line: _], [{:__aliases__, [line: _], aliases}, _other]} = ast,
         acc
       ) do
    module_name = Util.ast_module_name_to_atom(aliases)
    acc = %{acc | current_module: module_name}
    {ast, acc}
  end

  defp collect_record_info(
         {{:., [line: line], aliases}, _, params} = ast,
         %{current_module: module, records: records} = acc
       ) do
    case aliases do
      [{:__aliases__, _, [:Record]}, record_def] when record_def in [:defrecord, :defrecordp] ->
        [name, fields] = params
        fields = for {field, _default_value} <- fields, do: field

        record =
          case record_def do
            :defrecord ->
              {module, name, :public, length(fields), fields, line}

            :defrecordp ->
              {module, name, :private, length(fields), fields, line}
          end

        {ast, %{acc | records: [record | records]}}

      _ ->
        # not a record definition
        {ast, acc}
    end
  end

  # E.g.:
  # {:{}, [line: 11], [:priv_record, {:variable, [line: 11], nil}, {:variable, [line: 11], nil}]}
  defp collect_record_info(
         {:{}, [line: _], [maybe_record_name | _args]} = ast,
         %{current_module: module, records: records} = acc
       )
       when is_atom(maybe_record_name) do

    case List.keyfind(records, maybe_record_name, 1, :not_found) do
      :not_found ->
        # it wasn't a record?
        {ast, acc}

      {^module, ^maybe_record_name, _scope, _fields, _line} ->
        # this is a record with the same name, but different number of arguments,
        # so an edge-case I don't know how to handle (this would create a different "record" than
        # the one defined we know about)
        {ast, acc}
    end
  end

  # E.g.:
  # {:{}, [line: _],[{:__aliases__, [line: _],[:PrivRecord]},{:variable, [line: _], nil},{:variable, [line: _], nil}]}
  defp collect_record_info(
         {:{}, [line: _], [{:__aliases__, [line: _], [maybe_record_name]} | _args]} = ast,
         %{current_module: module, records: records} = acc
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

      {^module, ^maybe_record_name, _scope, _field_count, _fields, _line} ->
        # this is a record with the same name, but different number of arguments,
        # so an edge-case I don't know how to handle (this would create a different "record" than
        # the one defined we know about)
        {ast, acc}
    end
  end

  # E.g.: record_name(record_name(), :record_field)
  defp collect_record_info(
         {maybe_record_name, [line: _], [{_, [line: _], _}, maybe_field]} = ast,
         %{current_module: module, records: records} = acc
       )
       when is_atom(maybe_record_name) and is_atom(maybe_field) do
    case List.keyfind(records, maybe_record_name, 1, :not_found) do
      :not_found ->
        # it wasn't a record
        {ast, acc}

      {^module, ^maybe_record_name, scope, field_count, fields, line} ->
        record = {module, maybe_record_name, scope, field_count, fields -- [maybe_field], line}
        new_records = List.keyreplace(records, maybe_record_name, 1, record)
        {ast, %{acc | records: new_records}}
    end
  end

  # {:spiderman,[line: 26],[{:spiderman,[line: 26],[]},[name: "Gwen Stacy",is_cool?: :heck_yeah]]}
  defp collect_record_info(
         {maybe_record_name, [line: _], [{_, [line: _], _}, maybe_fields]} = ast,
         %{current_module: module, records: records} = acc
       )
       when is_atom(maybe_record_name) and is_list(maybe_fields) do
    case List.keyfind(records, maybe_record_name, 1, :not_found) do
      :not_found ->
        # it wasn't a record
        {ast, acc}

      {^module, ^maybe_record_name, scope, field_count, fields, line} ->
        used_fields = for {field, _value} <- maybe_fields, do: field
        record = {module, maybe_record_name, scope, field_count, fields -- used_fields, line}
        new_records = List.keyreplace(records, maybe_record_name, 1, record)
        {ast, %{acc | records: new_records}}
    end
  end

  # E.g.: setting values: record_name(field1: value1, field2: value2, ...)
  defp collect_record_info(
         {maybe_record_name, [line: _], [maybe_fields]} = ast,
         %{current_module: module, records: records} = acc
       )
       when is_atom(maybe_record_name) and is_list(maybe_fields) do
    if Keyword.keyword?(maybe_fields) do
      case List.keyfind(records, maybe_record_name, 1, :not_found) do
        :not_found ->
          # it wasn't a record
          {ast, acc}

        {^module, ^maybe_record_name, scope, field_count, fields, line} ->
          used_fields = for {field, _value} <- maybe_fields, do: field
          record = {module, maybe_record_name, scope, field_count, fields -- used_fields, line}
          new_records = List.keyreplace(records, maybe_record_name, 1, record)
          {ast, %{acc | records: new_records}}
      end
    else
      {ast, acc}
    end
  end

  # E.g.: getting 0-based field index: record_name(:field)
  defp collect_record_info(
         {maybe_record_name, [line: _], [maybe_field]} = ast,
         %{current_module: module, records: records} = acc
       )
       when is_atom(maybe_record_name) and maybe_record_name != :__aliases__ and
              is_atom(maybe_field) do
    case List.keyfind(records, maybe_record_name, 1, :not_found) do
      :not_found ->
        # it wasn't a record
        {ast, acc}

      {^module, ^maybe_record_name, scope, field_count, fields, line} ->
        record = {module, maybe_record_name, scope, field_count, fields -- [maybe_field], line}
        new_records = List.keyreplace(records, maybe_record_name, 1, record)
        {ast, %{acc | records: new_records}}
    end
  end

  # Record updating
  # E.g.: record_name(record_variable, :record_field)
  defp collect_record_info(
         {record_name, [line: _], [{:record, _, _}, field]} = ast,
         %{current_module: module, records: records} = acc
       )
       when is_atom(record_name) and is_atom(field) do
    {^module, ^record_name, scope, fields, line} = List.keyfind(records, record_name, 1)

    record = {module, record_name, scope, fields -- [field], line}
    new_records = List.keyreplace(records, record_name, 1, record)
    {ast, %{acc | records: new_records}}
  end

  # not a record
  defp collect_record_info(other, acc) do
    {other, acc}
  end
end
