defmodule MeandroTest.Rule.UnnecessaryFunctionArguments do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnnecessaryFunctionArguments

  @test_directory_path "test/rules/unnecessary_function_arguments/"

  test "emits no warnings on files without function arguments" do
    files_and_asts = parse_files(["none.exs"])
    assert [] = Rule.analyze(UnnecessaryFunctionArguments, files_and_asts, :nocontext)
  end

  test "emits no warnings on files where all function arguments are used" do
    files_and_asts = parse_files(["good.exs"])
    assert [] = Rule.analyze(UnnecessaryFunctionArguments, files_and_asts, :nocontext)
  end

  test "emits warnings on files where a function argument is unused" do
    file = "bad.exs"
    module = read_module_name(file)

    expected_warnings = [
      {4, :ignore, 1, 1},
      {7, :ignore, 2, 2},
      {10, :also_ignore, 2, 2},
      {17, :private, 5, 2},
      {17, :private, 5, 3}
    ]

    expected_results =
      for {line, function, arity, position} <- expected_warnings do
        %Meandro.Rule{
          file: @test_directory_path <> "bad.exs",
          line: line,
          pattern: {function, arity, position},
          rule: Meandro.Rule.UnnecessaryFunctionArguments,
          text:
            "Argument in position #{position} of #{module}.#{function}/#{arity} is ignored in all of its clauses"
        }
      end

    files_and_asts = parse_files([file])

    assert ^expected_results =
             Enum.sort(Rule.analyze(UnnecessaryFunctionArguments, files_and_asts, :nocontext))
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
  end
end
