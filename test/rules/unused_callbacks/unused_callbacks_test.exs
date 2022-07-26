defmodule MeandroTest.Rule.UnusedCallbacks do
  use ExUnit.Case

  alias Meandro.Rule.UnusedCallback

  test "with warnings" do
    file1 = "implementation.exs"
    file2 = "uri_parser_behaviour.exs"
    files_and_asts = [{file1, []}, {file2, []}]
    [implementation_analyze_result, uri_parser_analyze_result] = UnusedCallback.analyze(files_and_asts, [])
    assert %{:file => ^file1} = implementation_analyze_result
    assert %{:file => ^file2} = uri_parser_analyze_result
  end
end
