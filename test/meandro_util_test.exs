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
      input_file = "test/mix/examples/test_app.exs"
      parsed = Meandro.Util.parse_files([input_file], parsing_type)
      [{^input_file, [{:"MeandroTest.Examples.TestApp", _ast1}, {:"MeandroTest.Examples.TestApp2", _ast2}]}] = parsed
    end)
  end

  test "split the file asts on nested modules" do
    in_both_parsing_types(fn parsing_type ->
      input_file = "test/mix/examples/nested_modules.exs"
      parsed = Meandro.Util.parse_files([input_file], parsing_type)

      [{^input_file, [{:"MeandroTest.Examples.MainModule", _ast1}, {:"MeandroTest.Examples.NestedModule", _ast2}]}] =
        parsed
    end)
  end

  test "parsing all the modules" do
    in_both_parsing_types(fn parsing_type ->
      input_files = ["test/mix/examples/nested_modules.exs", "test/mix/examples/test_app.exs"]
      parsed = Meandro.Util.parse_files(input_files, parsing_type)

      [
        {"test/mix/examples/nested_modules.exs",
         [{:"MeandroTest.Examples.MainModule", _ast1}, {:"MeandroTest.Examples.NestedModule", _ast2}]},
        {"test/mix/examples/test_app.exs",
         [{:"MeandroTest.Examples.TestApp", _ast3}, {:"MeandroTest.Examples.TestApp2", _ast4}]}
      ] = parsed
    end)
  end
end
