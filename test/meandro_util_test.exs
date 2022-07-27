defmodule MeandroTest.Util do
  use ExUnit.Case

  defp in_both_parsing_types(func) do
    [:sequential, :parallel]
    |> Enum.each(fn parsing_type ->
      func.(parsing_type)
    end)
  end

  test "split the file asts on one file:multiple modules" do
    in_both_parsing_types(fn parsing_type ->
      input_file = "test/mix/files/test_app.exs"
      parsed = Meandro.Util.parse_files([input_file], parsing_type)
      [{^input_file, [{:"Mix.Files.TestApp2", _ast1}, {:"Mix.Files.TestApp", _ast2}]}] = parsed
    end)
  end

  test "split the file asts on nested modules" do
    in_both_parsing_types(fn parsing_type ->
      input_file = "test/mix/files/nested_modules.exs"
      parsed = Meandro.Util.parse_files([input_file], parsing_type)

      [{^input_file, [{:"Mix.Files.NestedModule", _ast1}, {:"Mix.Files.MainModule", _ast2}]}] =
        parsed
    end)
  end

  test "parsing all the modules" do
    in_both_parsing_types(fn parsing_type ->
      input_files = ["test/mix/files/nested_modules.exs", "test/mix/files/test_app.exs"]
      parsed = Meandro.Util.parse_files(input_files, parsing_type)

      [
        {"test/mix/files/nested_modules.exs",
         [{:"Mix.Files.NestedModule", _ast1}, {:"Mix.Files.MainModule", _ast2}]},
        {"test/mix/files/test_app.exs",
         [{:"Mix.Files.TestApp2", _ast3}, {:"Mix.Files.TestApp", _ast4}]}
      ] = parsed
    end)
  end
end
