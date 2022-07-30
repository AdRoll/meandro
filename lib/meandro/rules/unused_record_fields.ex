defmodule Meandro.Rule.UnusedRecordFields do
  @moduledoc """
  Finds instances where a record has fields defined that are not being used.

  This rule assumes that your code will never use the underlying tuple
  structure of your records directly.
  """

  @behaviour Meandro.Rule

  alias Meandro.Util

  @impl Meandro.Rule
  def analyze(files_and_asts, _options) do
    for {file, module_asts} <- files_and_asts,
        {_module_name, ast} <- module_asts,
        result <- analyze_module(file, ast, files_and_asts) do
      result
    end
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
    {_, acc} =
      Macro.prewalk(
        ast,
        %{tracking_mode: :all, current_module: nil, records: []},
        &collect_record_info/2
      )

    for {module, name, scope, _field_count, unused_fields, line} = record <-
          Enum.reverse(acc[:records]),
        unused_field <- unused_fields,
        is_unused?(record, files_and_asts) do
      camel_name = name |> Atom.to_string() |> Macro.camelize()
      scope_str = scope |> Atom.to_string() |> String.capitalize()

      %Meandro.Rule{
        file: file,
        line: line,
        text:
          "#{scope_str} record :#{name} (#{camel_name}) has an unused field in the module: #{unused_field}",
        pattern: {name, unused_field}
      }
    end
  end

  defp is_unused?(_record, []), do: true
  defp is_unused?({_module, _name, _scope, _field_count, [], _line}, _), do: false
  # we don't need to check the other files because it's private
  defp is_unused?({_module, _name, :private, _field_count, _unused_fields, _line}, _), do: true

  defp is_unused?(record, [{_file, ast} | tl]) do
    {_, acc} =
      Macro.prewalk(
        ast,
        %{tracking_mode: :usage, current_module: nil, records: [record]},
        &collect_record_info/2
      )

    {module, name, scope, field_count, _unused_fields, line} = record

    case List.keyfind(acc[:records], name, 1) do
      nil ->
        is_unused?(record, tl)

      {^module, ^name, ^scope, ^field_count, [], ^line} ->
        false

      _ ->
        is_unused?(record, tl)
    end
  end

  defp collect_record_info(
         {:defmodule, [line: _], [{:__aliases__, [line: _], aliases}, _other]} = ast,
         acc
       ) do
    module_name = Util.ast_module_name_to_atom(aliases)
    {ast, %{acc | current_module: module_name}}
  end

  # module import definitions, we need to track them to know if a given file
  # will be using a record we know was defined in another file
  defp collect_record_info(
         {:import, [line: _], [{:__aliases__, [line: _], [imported_module]}]} = ast,
         %{tracking_mode: :usage, records: records} = acc
       ) do
    case List.keyfind(records, imported_module, 0) do
      nil ->
        # a module was imported, but it didn't contain records we know about,
        # so we can stop matching against this file
        {ast, %{acc | tracking_mode: :none}}

      {^imported_module, _record_name, _scope, _field_count, _fields, _line} ->
        {ast, acc}
    end
  end

  # record definition (Record.defrecord/3 or Record.defrecordp/3 calls)
  # we only want to do this when tracking all record information (definitions + usage)
  defp collect_record_info(
         {{:., [line: line], aliases}, _, params} = ast,
         %{tracking_mode: :all, current_module: module, records: records} = acc
       ) do
    # We need to be careful here because sometimes params is not a list of params.
    # Particularly when we use Record.extract/2
    case {aliases, params} do
      {[{:__aliases__, _, [:Record]}, record_def], [name, fields]}
      when record_def in [:defrecord, :defrecordp] and is_list(fields) ->
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

  # E.g.: record_name(record_name(), :record_field)
  defp collect_record_info(
         {maybe_record_name, [line: _], [{_, [line: _], _}, maybe_field]} = ast,
         %{tracking_mode: tracking_mode} = acc
       )
       when tracking_mode != :none and is_atom(maybe_record_name) and is_atom(maybe_field) do
    do_collect_record_info(maybe_record_name, [maybe_field], ast, acc)
  end

  # {:spiderman,[line: 26],[{:spiderman,[line: 26],[]},[name: "Gwen Stacy",is_cool?: :heck_yeah]]}
  defp collect_record_info(
         {maybe_record_name, [line: _], [{_, [line: _], _}, maybe_fields]} = ast,
         %{tracking_mode: tracking_mode} = acc
       )
       when tracking_mode != :none and is_atom(maybe_record_name) and is_list(maybe_fields) do
    used_fields = for {field, _value} <- maybe_fields, do: field
    do_collect_record_info(maybe_record_name, used_fields, ast, acc)
  end

  # E.g.: setting values: record_name(field1: value1, field2: value2, ...)
  defp collect_record_info(
         {maybe_record_name, [line: _], [maybe_fields]} = ast,
         %{tracking_mode: tracking_mode} = acc
       )
       when tracking_mode != :none and is_atom(maybe_record_name) and is_list(maybe_fields) do
    used_fields = for {field, _value} <- maybe_fields, do: field
    do_collect_record_info(maybe_record_name, used_fields, ast, acc)
  end

  # E.g.: getting 0-based field index: record_name(:field)
  defp collect_record_info(
         {maybe_record_name, [line: _], [maybe_field]} = ast,
         %{tracking_mode: tracking_mode} = acc
       )
       when tracking_mode != :none and is_atom(maybe_record_name) and
              maybe_record_name != :__aliases__ and
              is_atom(maybe_field) do
    do_collect_record_info(maybe_record_name, [maybe_field], ast, acc)
  end

  # Record updating
  # E.g.: record_name(record_variable, :record_field)
  defp collect_record_info(
         {record_name, [line: _], [{:record, _, _}, field]} = ast,
         %{tracking_mode: tracking_mode} = acc
       )
       when tracking_mode != :none and is_atom(record_name) and is_atom(field) do
    do_collect_record_info(record_name, [field], ast, acc)
  end

  # catch-all clause
  defp collect_record_info(other, acc) do
    {other, acc}
  end

  defp do_collect_record_info(
         maybe_record_name,
         used_fields,
         ast,
         %{current_module: module, records: records} = acc
       ) do
    case List.keyfind(records, maybe_record_name, 1) do
      nil ->
        # it wasn't a record
        {ast, acc}

      {^module, ^maybe_record_name, scope, field_count, fields, line} ->
        # record being used in the same module it was defined
        record = {module, maybe_record_name, scope, field_count, fields -- used_fields, line}
        new_records = List.keyreplace(records, maybe_record_name, 1, record)
        {ast, %{acc | records: new_records}}

      {module, ^maybe_record_name, scope, field_count, fields, line} ->
        # record being used in an external module
        record = {module, maybe_record_name, scope, field_count, fields -- used_fields, line}
        new_records = List.keyreplace(records, maybe_record_name, 1, record)
        {ast, %{acc | records: new_records}}
    end
  end
end
