defmodule Mix.Tasks.MeandroTest do
  use ExUnit.Case

  test "run mix meandro" do
    input_files = "mix/files/test_app.exs"

    assert Mix.Tasks.Meandro.run(["--files", input_files]) == %{
             results: [],
             stats: %{analyzing: nil, ignored: nil, parsing: nil, total: nil},
             unused_ignores: []
           }
  end
end
