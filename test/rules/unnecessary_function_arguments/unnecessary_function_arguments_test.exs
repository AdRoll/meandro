defmodule MeandroTest.Rule.UnnecessaryFunctionArguments do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnnecessaryFunctionArguments

  @test_directory_path "test/rules/unnecessary_function_arguments/examples/"

  test "emits no warnings on files without function arguments" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "none.exs"])
    assert [] = Rule.analyze(UnnecessaryFunctionArguments, files_and_asts, [])
  end

  test "emits no warnings on files where all function arguments are used" do
    files_and_asts = TestHelpers.parse_files([@test_directory_path <> "good.exs"])
    assert [] = Rule.analyze(UnnecessaryFunctionArguments, files_and_asts, [])
  end

  test "emits warnings on files where a function argument is unused" do
    file = @test_directory_path <> "bad.exs"
    module = TestHelpers.read_module_name(file)

    expected_warnings = [
      {5, :ignore, 1, 1},
      {8, :ignore, 2, 2},
      {11, :also_ignore, 2, 2},
      {18, :private, 5, 2},
      {18, :private, 5, 3}
    ]

    expected_results =
      for {line, function, arity, position} <- expected_warnings do
        %Meandro.Rule{
          module: module,
          file: @test_directory_path <> "bad.exs",
          line: line,
          pattern: {function, arity, position},
          rule: Meandro.Rule.UnnecessaryFunctionArguments,
          text:
            "Argument in position #{position} of #{module}.#{function}/#{arity} is ignored in all of its clauses"
        }
      end

    files_and_asts = TestHelpers.parse_files([file])

    assert ^expected_results =
             UnnecessaryFunctionArguments
             |> Rule.analyze(files_and_asts, [])
             |> Enum.sort()
  end

  test "handles exceptions and edge cases correctly" do
    file = @test_directory_path <> "edges.exs"
    module = :"MeandroTest.Examples.UnnecessaryFunctionArguments.BehaviourImplementation"

    expected_warnings = [
      {18, :another_callback, 1, 1},
      {23, :warn, 1, 1}
    ]

    expected_results =
      for {line, function, arity, position} <- expected_warnings do
        %Rule{
          module: module,
          file: @test_directory_path <> "edges.exs",
          line: line,
          pattern: {function, arity, position},
          rule: UnnecessaryFunctionArguments,
          text:
            "Argument in position #{position} of #{module}.#{function}/#{arity} is ignored in all of its clauses"
        }
      end

    files_and_asts = TestHelpers.parse_files([file])

    assert ^expected_results =
             UnnecessaryFunctionArguments
             |> Rule.analyze(files_and_asts, [])
             |> Enum.sort()
  end
end
