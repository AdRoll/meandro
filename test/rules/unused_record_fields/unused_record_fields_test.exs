defmodule MeandroTest.UnusedRecordFields do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedRecordFields

  @test_directory_path "test/rules/unused_record_fields/examples/"

  test "emits no warnings on files without records" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "none.exs"])
    assert [] = Rule.analyze(UnusedRecordFields, files_and_asts, [])
  end

  test "emits no warnings on files where all field records are used" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "good.exs"])
    assert [] = Rule.analyze(UnusedRecordFields, files_and_asts, [])
  end

  test "emits no warnings when it can't infer the record fields" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "extract.exs"])
    assert [] = Rule.analyze(UnusedRecordFields, files_and_asts, :nocontext)
  end

  test "emits warnings on files where a record has unused field(s)" do
    file = @test_directory_path <> "bad.exs"
    files_and_asts = TestHelpers.parse_files([file])
    record = read_records(file)
    [{camel_name, atom_name, fields}] = record
    [unused_field1, unused_field2] = fields

    expected_text1 =
      "Public record :#{atom_name} (#{camel_name}) has an unused field in the module: #{unused_field1}"

    expected_text2 =
      "Public record :#{atom_name} (#{camel_name}) has an unused field in the module: #{unused_field2}"

    assert [
             %Rule{
               file: ^file,
               line: 3,
               pattern: {^atom_name, ^unused_field1},
               rule: UnusedRecordFields,
               text: ^expected_text1
             },
             %Rule{
               file: ^file,
               line: 3,
               pattern: {^atom_name, ^unused_field2},
               rule: UnusedRecordFields,
               text: ^expected_text2
             }
           ] = Rule.analyze(UnusedRecordFields, files_and_asts, [])
  end

  test "ONLY emits warnings on files where a record has unused field(s)" do
    bad_file = @test_directory_path <> "bad.exs"

    files_and_asts =
      TestHelpers.parse_files([
        @test_directory_path <> "none.exs",
        @test_directory_path <> "good.exs",
        bad_file
      ])

    record = read_records(bad_file)
    [{camel_name, atom_name, fields}] = record
    [unused_field1, unused_field2] = fields

    expected_text1 =
      "Public record :#{atom_name} (#{camel_name}) has an unused field in the module: #{unused_field1}"

    expected_text2 =
      "Public record :#{atom_name} (#{camel_name}) has an unused field in the module: #{unused_field2}"

    assert [
             %Rule{
               file: ^bad_file,
               line: 3,
               pattern: {^atom_name, ^unused_field1},
               rule: UnusedRecordFields,
               text: ^expected_text1
             },
             %Rule{
               file: ^bad_file,
               line: 3,
               pattern: {^atom_name, ^unused_field2},
               rule: UnusedRecordFields,
               text: ^expected_text2
             }
           ] = Rule.analyze(UnusedRecordFields, files_and_asts, [])
  end

  test "emits warnings on files with multiple records, only when there are unused fields" do
    file = @test_directory_path <> "mixed.exs"
    files_and_asts = TestHelpers.parse_files([file])
    [record1, _record2] = read_records(file)
    {camel_name, atom_name, fields} = record1
    [unused_field] = Enum.filter(fields, fn s -> s == :unused end)

    expected_text =
      "Public record :#{atom_name} (#{camel_name}) has an unused field in the module: #{unused_field}"

    assert [
             %Rule{
               file: ^file,
               line: 3,
               pattern: {^atom_name, ^unused_field},
               rule: UnusedRecordFields,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedRecordFields, files_and_asts, [])
  end

  test "emits warnings on files with multiple records, when there are only unused fields" do
    file = @test_directory_path <> "bad_multiple_records.exs"
    files_and_asts = TestHelpers.parse_files([file])
    [record1, record2] = read_records(file)
    {camel_name1, atom_name1, [unused_field1]} = record1
    {camel_name2, atom_name2, [unused_field2]} = record2

    expected_text1 =
      "Public record :#{atom_name1} (#{camel_name1}) has an unused field in the module: #{unused_field1}"

    expected_text2 =
      "Private record :#{atom_name2} (#{camel_name2}) has an unused field in the module: #{unused_field2}"

    assert [
             %Rule{
               file: ^file,
               line: 3,
               pattern: {^atom_name1, ^unused_field1},
               rule: UnusedRecordFields,
               text: ^expected_text1
             },
             %Rule{
               file: ^file,
               line: 4,
               pattern: {^atom_name2, ^unused_field2},
               rule: UnusedRecordFields,
               text: ^expected_text2
             }
           ] = Rule.analyze(UnusedRecordFields, files_and_asts, [])
  end

  test "using record fields with each of the record functions/syntaxes counts as them being used" do
    file = @test_directory_path <> "exhaustive.exs"
    files_and_asts = TestHelpers.parse_files([file])

    assert [] = Rule.analyze(UnusedRecordFields, files_and_asts, [])
  end

  test "does not emit warnings for record fields unused locally but used in other modules" do
    file = @test_directory_path <> "multiple_modules.exs"
    files_and_asts = TestHelpers.parse_files([file])

    assert [] = Rule.analyze(UnusedRecordFields, files_and_asts, [])
  end

  defp read_records(file_path) do
    {:ok, contents} = File.read(file_path)
    pattern = ~r{Record\.defrecordp?\([:a-zA-Z](.*)\)}x

    pattern
    |> Regex.scan(contents, capture: :all_but_first)
    |> List.flatten()
    |> Enum.map(&parse_str_record/1)
  end

  defp parse_str_record(str_record) do
    [str_record_name | str_fields] = String.split(str_record, ", ")
    record_name_camelized = str_record_name |> Macro.camelize() |> String.to_atom()
    record_name = String.to_atom(str_record_name)

    fields =
      Enum.map(str_fields, fn str_field ->
        [field_name, _value] = String.split(str_field, ": ")
        String.to_atom(field_name)
      end)

    {record_name_camelized, record_name, fields}
  end
end
