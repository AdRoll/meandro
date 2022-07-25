defmodule MeandroTest.Rule.UnusedCallbacks do
  use ExUnit.Case

  test "with warnings" do
    files_and_asts = [{"implementation.exs", []}, {"uri_parser_behaviour.exs", []}]
    assert Meandro.Rule.UnusedCallback.analyze(files_and_asts, []) == []
  end
end
