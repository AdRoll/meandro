defmodule Mix.Tasks.MeandroTest do
  use ExUnit.Case

  alias Mix.Tasks.Meandro

  test "run mix meandro" do
    input_files = "test/mix/files/test_app.exs"

    assert Meandro.run(["--files", input_files]) == %{
             results: [],
             stats: %{analyzing: nil, ignored: nil, parsing: nil, total: nil},
             unused_ignores: []
           }
  end
end
