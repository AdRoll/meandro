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

  defp parse_files(paths) do
    files = for p <- paths, do: @test_directory_path <> p
    Meandro.Util.parse_files(files, :sequential)
  end
end
