defmodule Meandro do
  # @todo add docs and @moduledoc
  @moduledoc """
  Documentation for `Meandro`.
  """

  @doc """
  Analyze
  """
  def analyze(files, rules) do
    #asts = parse_files(files)
    %{results: [],
      unused_ignores: [],
      stats:
          %{ignored: nil,
            parsing: nil,
            analyzing:  nil,
            total: nil}}
  end

  defp parse_files(files) do
    # @todo get the AST for all the files
    files
  end
end
