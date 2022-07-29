defmodule Mix.Tasks.MeandroTest do
  use ExUnit.Case

  alias Mix.Tasks.Meandro

  test "run mix meandro with --files" do
    input_files = "test/mix/examples/test_app.exs"

    assert :ok == Meandro.run(["--files", input_files])
  end
end
