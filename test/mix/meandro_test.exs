defmodule Mix.Tasks.MeandroTest do
  use ExUnit.Case

  alias Mix.Tasks.Meandro

  test "run mix meandro with --files" do
    input_files = "test/mix/examples/test_app.exs"

    assert Meandro.run(["--files", input_files]) == %{
             results: [],
             stats: %{ignored: 0, total: 1, analyzed: 1, parsed: 1},
             unused_ignores: []
           }
  end
end
