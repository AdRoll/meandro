defmodule MeandroTest.Rule.UnusedCallbacks do
  use ExUnit.Case

  alias Meandro.Rule.UnusedCallback

  test "with warnings" do
    files_and_asts = [{"implementation.exs", []}, {"uri_parser_behaviour.exs", []}]
    assert UnusedCallback.analyze(files_and_asts, []) == []
  end
end
