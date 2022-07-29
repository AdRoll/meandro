defmodule MeandroTest.UnusedStructFields do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedStructFields

  @test_directory_path "test/rules/unused_struct_fields/examples/"

  test "emits no warnings on files without structs" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "none.exs"])
    assert [] = Rule.analyze(UnusedStructFields, files_and_asts, [])
  end

  test "emits no warnings on structs where all fields are used" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "good.exs"])
    assert [] = Rule.analyze(UnusedStructFields, files_and_asts, [])
  end

  test "emits warnings on structs where all fields are unused" do
    file = @test_directory_path <> "all_unused.exs"
    files_and_asts = TestHelpers.parse_files([file])

    expected_text1 =
      "The field lat from the struct MeandroTest.Examples.UnusedStructFields.Unused is unused"

    expected_text2 =
      "The field long from the struct MeandroTest.Examples.UnusedStructFields.Unused is unused"

    assert [
             %Rule{
               file: ^file,
               rule: UnusedStructFields,
               text: ^expected_text1
             },
             %Rule{
               file: ^file,
               rule: UnusedStructFields,
               text: ^expected_text2
             }
           ] = Rule.analyze(UnusedStructFields, files_and_asts, [])
  end

  test "emits warnings on structs where at least one field is unused" do
    file = @test_directory_path <> "one_unused.exs"
    files_and_asts = TestHelpers.parse_files([file])

    expected_text =
      "The field lat from the struct MeandroTest.Examples.UnusedStructFields.OneUnused is unused"

    assert [
             %Rule{
               file: ^file,
               rule: UnusedStructFields,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedStructFields, files_and_asts, [])
  end

  test "emits no warnings on structs where fields are accessed" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "access_field.exs"])
    assert [] = Rule.analyze(UnusedStructFields, files_and_asts, [])
  end

  test "emits no warnings on structs where fields are modified" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "modify_field.exs"])
    assert [] = Rule.analyze(UnusedStructFields, files_and_asts, [])
  end

  test "emits no warnings on structs where fields are used from other files" do
    files_and_asts =
      TestHelpers.parse_files([
        @test_directory_path <> "all_unused.exs",
        @test_directory_path <> "init_struct_from_other_module.exs"
      ])

    assert [] = Rule.analyze(UnusedStructFields, files_and_asts, [])
  end

  describe "the struct is only used to pattern match a function header" do
    test "emits no warnings when all fields are used in a pattern match" do
      files_and_asts = TestHelpers.parse_files([@test_directory_path <> "pattern_match_good.exs"])
      assert [] = Rule.analyze(UnusedStructFields, files_and_asts, [])
    end

    test "emits a warning when a field is unused in a pattern match" do
      file = @test_directory_path <> "pattern_match_bad.exs"

      expected_text =
        "The field long from the struct MeandroTest.Examples.UnusedStructFields.Source is unused"

      files_and_asts = TestHelpers.parse_files([file])

      assert [
               %Rule{
                 file: ^file,
                 rule: UnusedStructFields,
                 text: ^expected_text
               }
             ] = Rule.analyze(UnusedStructFields, files_and_asts, [])
    end
  end
end
