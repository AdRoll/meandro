defmodule MeandroTest.Ignore do
  use ExUnit.Case

  @test_directory_path "test/ignores/examples/"

  test "emits no warnings on files with one ignores" do
    files = [@test_directory_path <> "one_ignored.exs"]
    rules = [Meandro.Rule.UnusedStructFields]

    assert %{
             results: [],
             stats: %{analyzed: 1, ignored: 1, parsed: 1, total: 1},
             unused_ignores: []
           } = Meandro.analyze(files, rules, :sequential)
  end

  test "emits no warnings on files with several ignores" do
    files = [@test_directory_path <> "several_ignored.exs"]
    rules = [Meandro.Rule.UnusedCallbacks, Meandro.Rule.UnusedMacros]

    assert %{
             results: [],
             stats: %{analyzed: 1, ignored: 3, parsed: 1, total: 1},
             unused_ignores: []
           } = Meandro.analyze(files, rules, :sequential)
  end
end
