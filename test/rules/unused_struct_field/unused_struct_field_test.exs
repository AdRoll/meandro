defmodule MeandroTest.Rule.UnusedStructField do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedStructField

  @test_directory_path "test/rules/unused_struct_field/"

  test "emits no warnings on files without structs" do
    files_and_asts = parse_files(["none.exs"])
    assert [] = Rule.analyze(UnusedStructField, files_and_asts, :nocontext)
  end

  test "emits no warnings on structs where all fields are used" do
    files_and_asts = parse_files(["good.exs"])
    assert [] = Rule.analyze(UnusedStructField, files_and_asts, :nocontext)
  end

  test "emits warnings on structs where all fields are unused" do
    files_and_asts = parse_files(["all_unused.exs"])
    expected_text1 = "The field lat from the struct MeandroTest.MyStructTest is unused"
    expected_text2 = "The field long from the struct MeandroTest.MyStructTest is unused"

    assert [
             %Meandro.Rule{
               file: @test_directory_path <> "all_unused.exs",
               rule: Meandro.Rule.UnusedStructField,
               text: ^expected_text1
             },
             %Meandro.Rule{
               file: @test_directory_path <> "all_unused.exs",
               rule: Meandro.Rule.UnusedStructField,
               text: ^expected_text2
             }
           ] = Rule.analyze(UnusedStructField, files_and_asts, :nocontext)
  end

  test "emits warnings on structs where at least one field is unused" do
    files_and_asts = parse_files(["one_unused.exs"])
    expected_text = "The field lat from the struct MeandroTest.MyStructTest is unused"

    assert [
             %Meandro.Rule{
               file: @test_directory_path <> "one_unused.exs",
               rule: Meandro.Rule.UnusedStructField,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedStructField, files_and_asts, :nocontext)
  end

  test "emits no warnings on structs where fields are accessed" do
    files_and_asts = parse_files(["access_field.exs"])
    assert [] = Rule.analyze(UnusedStructField, files_and_asts, :nocontext)
  end

  test "emits no warnings on structs where fields are modified" do
    files_and_asts = parse_files(["modify_field.exs"])
    assert [] = Rule.analyze(UnusedStructField, files_and_asts, :nocontext)
  end

  test "emits no warnings on structs where fields are used from other files" do
    files_and_asts = parse_files(["all_unused.exs", "init_struct_from_other_module.exs"])
    assert [] = Rule.analyze(UnusedStructField, files_and_asts, :nocontext)
  end

  describe "the struct is only used to pattern match a function header" do
    test "emits no warnings when all fields are used in a pattern match" do
      files_and_asts = parse_files(["pattern_match_good.exs"])
      assert [] = Rule.analyze(UnusedStructField, files_and_asts, :nocontext)
    end

    test "emits a warning when a field is unused in a pattern match" do
      expected_text = "The field long from the struct MeandroTest.MyStructTest is unused"
      files_and_asts = parse_files(["pattern_match_bad.exs"])
      assert [
        %Meandro.Rule{
          file: @test_directory_path <> "pattern_match_bad.exs",
          rule: Meandro.Rule.UnusedStructField,
          text: ^expected_text
        }
      ] = Rule.analyze(UnusedStructField, files_and_asts, :nocontext)
    end
  end

  defp parse_files(paths) do
    files = for p <- paths, do: @test_directory_path <> p
    Meandro.Util.parse_files(files, :sequential)
  end
end
