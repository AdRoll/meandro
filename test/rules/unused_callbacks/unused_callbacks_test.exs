defmodule MeandroTest.Rule.UnusedCallbacks do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedCallbacks

  @test_directory_path "test/rules/unused_callbacks/"

  test "emits no warnings on files without callbacks" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "none.exs"])
    assert [] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "emits no warnings on files where all callbacks are used" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "good.exs"])
    assert [] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "emits warnings on nested modules using parent callbacks" do
    file = @test_directory_path <> "nested.exs"
    module = TestHelpers.read_module_name(file)
    files_and_asts = TestHelpers.parse_files([file])
    expected_text = "Callback #{module}:used_incorrectly/0 is not used anywhere in the module"

    assert [
             %Rule{
               file: ^file,
               line: 3,
               pattern: {:used_incorrectly, 0},
               rule: UnusedCallbacks,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "it's not fooled by multiple modules with the same callback names" do
    file = @test_directory_path <> "multi.exs"
    files_and_asts = TestHelpers.parse_files([file])

    expected_text =
      "Callback MeandroTest.MultiExtra:used_only_once/1 is not used anywhere in the module"

    assert [
             %Rule{
               file: ^file,
               line: 16,
               pattern: {:used_only_once, 1},
               rule: UnusedCallbacks,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "emits warnings on files where a callback is unused, and the warnings are sorted" do
    file = @test_directory_path <> "bad.exs"
    module = TestHelpers.read_module_name(file)
    files_and_asts = TestHelpers.parse_files([file])
    expected_text1 = "Callback #{module}:unused/0 is not used anywhere in the module"
    expected_text2 = "Callback #{module}:unused_too/0 is not used anywhere in the module"

    assert [
             %Rule{
               file: ^file,
               line: 5,
               pattern: {:unused, 0},
               rule: UnusedCallbacks,
               text: ^expected_text1
             },
             %Rule{
               file: ^file,
               line: 6,
               pattern: {:unused_too, 0},
               rule: UnusedCallbacks,
               text: ^expected_text2
             }
           ] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "ONLY emits warnings on files where a callback is unused" do
    bad_file = @test_directory_path <> "bad.exs"
    module = TestHelpers.read_module_name(bad_file)

    files_and_asts =
      TestHelpers.parse_files([
        @test_directory_path <> "none.exs",
        @test_directory_path <> "good.exs",
        bad_file
      ])

    expected_text1 = "Callback #{module}:unused/0 is not used anywhere in the module"
    expected_text2 = "Callback #{module}:unused_too/0 is not used anywhere in the module"

    assert [
             %Rule{
               file: ^bad_file,
               line: 5,
               pattern: {:unused, 0},
               rule: UnusedCallbacks,
               text: ^expected_text1
             },
             %Rule{
               file: ^bad_file,
               line: 6,
               pattern: {:unused_too, 0},
               rule: UnusedCallbacks,
               text: ^expected_text2
             }
           ] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end
end
