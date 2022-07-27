defmodule MeandroTest.Rule.UnusedCallbacks do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedCallbacks

  @test_directory_path "test/rules/unused_callbacks/"

  test "emits no warnings on files without callbacks" do
    files_and_asts = parse_files(["none.exs"])
    assert [] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "emits no warnings on files where all callbacks are used" do
    files_and_asts = parse_files(["good.exs"])
    assert [] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "emits warnings on files where a callback is unused" do
    file = "bad.exs"
    module = read_module_name(file)
    files_and_asts = parse_files([file])
    expected_text = "Callback #{module}:unused/0 is not used anywhere in the module"

    assert [
             %Meandro.Rule{
               file: @test_directory_path <> "bad.exs",
               line: 5,
               pattern: {^module, :unused, 0},
               rule: Meandro.Rule.UnusedCallbacks,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  test "ONLY emits warnings on files where a callback is unused" do
    bad_file = "bad.exs"
    module = read_module_name("bad.exs")
    files_and_asts = parse_files(["none.exs", "good.exs", bad_file])
    expected_text = "Callback #{module}:unused/0 is not used anywhere in the module"

    assert [
             %Meandro.Rule{
               file: @test_directory_path <> "bad.exs",
               line: 5,
               pattern: {^module, :unused, 0},
               rule: Meandro.Rule.UnusedCallbacks,
               text: ^expected_text
             }
           ] = Rule.analyze(UnusedCallbacks, files_and_asts, :nocontext)
  end

  defp parse_files(paths) do
    files = for p <- paths, do: @test_directory_path <> p
    Meandro.Util.parse_files(files, :sequential)
  end

  defp read_module_name(file_path) do
    {:ok, contents} = File.read("test/rules/unused_callbacks/" <> file_path)
    pattern = ~r{defmodule \s+ ([^\s]+) }x

    Regex.scan(pattern, contents, capture: :all_but_first)
    |> List.flatten()
    |> List.first()
    |> String.to_atom()
  end
end
