defmodule Mix.Tasks.MeandroTest do
  use ExUnit.Case

  test "run mix meandro" do
    assert Mix.Tasks.Meandro.run() == %{results: [], stats: %{analyzing: nil, ignored: nil, parsing: nil, total: nil}, unused_ignores: []}
  end
end
