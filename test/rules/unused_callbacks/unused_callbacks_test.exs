defmodule MeandroTest.Rule.UnusedCallbacks do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedCallbacks

  test "emits no warnings on files without callbacks" do
    files_and_asts = parse_files(["none.exs"])
    assert [] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "emits no warnings on files where all callbacks are used" do
    files_and_asts = parse_files(["good.exs"])
    assert [] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "emits warnings on files where a callback is unused" do
    files_and_asts = parse_files(["bad.exs"])

    assert [
             %Meandro.Rule{
               file: "bad.exs",
               line: 5,
               pattern: {:unused, 0},
               rule: Meandro.Rule.UnusedCallbacks,
               text: "Callback unused/0 is not used anywhere in the module"
             }
           ] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "ONLY emits warnings on files where a callback is unused" do
    files_and_asts = parse_files(["none.exs", "good.exs", "bad.exs"])

    assert [
             %Meandro.Rule{
               file: "bad.exs",
               line: 5,
               pattern: {:unused, 0},
               rule: Meandro.Rule.UnusedCallbacks,
               text: "Callback unused/0 is not used anywhere in the module"
             }
           ] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  @doc "Copied from Meandro because it's private there"
  defp parse_files(paths) do
    Enum.map(paths, fn p ->
      f = File.open!("test/rules/unused_callbacks/" <> p)
      c = IO.read(f, :all)
      ast = Code.string_to_quoted!(c)
      {p, ast}
    end)
  end
end
