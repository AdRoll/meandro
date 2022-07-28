defmodule MeandroTest.Rule.UnusedMacrosTest do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedMacros

  @test_directory_path "test/rules/unused_macros/"

  test "emits no warnings on files without macros" do
    files_and_asts = parse_files(["none.exs"])
    assert [] = Rule.analyze(UnusedMacros, files_and_asts, :nocontext)
  end

  test "emits no warnings on files where all macros are used" do
    files_and_asts = parse_files(["good.exs"])
    assert [] = Rule.analyze(UnusedMacros, files_and_asts, :nocontext)
  end

  test "emits no warnings on files where one macro is used in the same module and other macro in other module" do
    files_and_asts = parse_files(["one_unused.exs", "use_macro_a.exs"])
    assert [] = Rule.analyze(UnusedMacros, files_and_asts, :nocontext)
  end

  test "emits warnings on files where not all macros are used" do
    files_and_asts = parse_files(["one_unused.exs"])

    assert [
             %Meandro.Rule{
               file: "test/rules/unused_macros/one_unused.exs",
               line: 2,
               pattern: {:"MeandroTest.MyMacroTest", :macro_a},
               rule: Meandro.Rule.UnusedMacros,
               text: "The macro macro_a is unused"
             }
           ] = Rule.analyze(UnusedMacros, files_and_asts, :nocontext)
  end

  defp parse_files(paths) do
    files = for p <- paths, do: @test_directory_path <> p
    Meandro.Util.parse_files(files, :sequential)
  end
end