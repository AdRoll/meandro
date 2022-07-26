defmodule MeandroTest.Util do
  use ExUnit.Case

  test "split the file asts on one file:multiple modules" do
    input_file = "test/mix/files/test_app.exs"

    parsed = Meandro.Util.parse_files([input_file], :sequential)
    [{^input_file, [{:"Mix.Files.TestApp2", _ast1}, {:"Mix.Files.TestApp", _ast2}]}] = parsed
  end
end
