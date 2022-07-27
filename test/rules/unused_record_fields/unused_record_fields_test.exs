defmodule MeandroTest.Rule.UnusedRecordFields do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedRecordFields

  @test_directory_path "test/rules/unused_record_fields/"

  test "emits no warnings on files without records" do
    files_and_asts = parse_files(["none.exs"])
    assert [] = Rule.analyze(UnusedRecordFields, files_and_asts, :nocontext)
  end

  test "emits no warnings on files where all field records are used" do
    files_and_asts = parse_files(["good.exs"])
    assert [] = Rule.analyze(UnusedRecordFields, files_and_asts, :nocontext)
  end

  test "emits warnings on files where a record has unused field(s)" do
    file = "bad.exs"
    module = read_module_name(file)
    files_and_asts = parse_files([file])
    record = read_records(file)
    [{camel_name, atom_name, fields}] = record

    expected_text =
      "Record :#{atom_name} (#{camel_name}) has the following unused fields in the module: #{inspect(fields)}"

    assert [
             %Meandro.Rule{
               file: @test_directory_path <> ^file,
               line: 3,
               pattern: {^module, ^atom_name, ^fields},
               rule: Meandro.Rule.UnusedRecordFields,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedRecordFields, files_and_asts, :nocontext)
  end

  test "ONLY emits warnings on files where a record has unused field(s)" do
    bad_file = "bad.exs"
    module = read_module_name("bad.exs")
    files_and_asts = parse_files(["none.exs", "good.exs", bad_file])
    record = read_records(bad_file)
    [{camel_name, atom_name, fields}] = record

    expected_text =
      "Record :#{atom_name} (#{camel_name}) has the following unused fields in the module: #{inspect(fields)}"

    assert [
             %Meandro.Rule{
               file: @test_directory_path <> ^bad_file,
               line: 3,
               pattern: {^module, ^atom_name, ^fields},
               rule: Meandro.Rule.UnusedRecordFields,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedRecordFields, files_and_asts, :nocontext)
  end

  test "emits warnings on files with multiple records, only when there are unused fields" do
    file = "mixed.exs"
    module = read_module_name(file)
    files_and_asts = parse_files([file])
    [record1, _record2] = read_records(file)
    {camel_name, atom_name, fields} = record1
    fields = Enum.filter(fields, fn s -> s == :unused end)

    expected_text =
      "Record :#{atom_name} (#{camel_name}) has the following unused fields in the module: #{inspect(fields)}"

    assert [
             %Meandro.Rule{
               file: @test_directory_path <> ^file,
               line: 3,
               pattern: {^module, ^atom_name, ^fields},
               rule: Meandro.Rule.UnusedRecordFields,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedRecordFields, files_and_asts, :nocontext)
  end

  defp parse_files(paths) do
    files = for p <- paths, do: @test_directory_path <> p
    Meandro.Util.parse_files(files, :sequential)
  end

  defp read_module_name(file_path) do
    {:ok, contents} = File.read(@test_directory_path <> file_path)
    pattern = ~r{defmodule \s+ ([^\s]+) }x

    Regex.scan(pattern, contents, capture: :all_but_first)
    |> List.flatten()
    |> List.first()
    |> String.to_atom()
  end

  defp read_records(file_path) do
    {:ok, contents} = File.read(@test_directory_path <> file_path)
    pattern = ~r{Record\.defrecordp?\([:a-zA-Z](.*)\)}x

    Regex.scan(pattern, contents, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&parse_str_record/1)
  end

  defp parse_str_record(str_record) do
    [record_name | fields] = String.split(str_record, ", ")
    record_name_camelized = Macro.camelize(record_name) |> String.to_atom()
    record_name = String.to_atom(record_name)

    fields =
      Enum.map(fields, fn str_field ->
        [field_name, _value] = String.split(str_field, ": ")
        String.to_atom(field_name)
      end)

    {record_name_camelized, record_name, fields}
  end
end
