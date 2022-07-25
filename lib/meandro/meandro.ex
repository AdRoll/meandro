defmodule Meandro do
  # @todo add docs and @moduledoc
  @moduledoc """
  Documentation for `Meandro`.
  """

  @doc """
  Analyze
  """
  def analyze(files, rules) do
    asts = parse_files(files)
    %{results: [],
      unused_ignores: [],
      stats:
          %{ignored: nil,
            parsing: nil,
            analyzing:  nil,
            total: nil}}
  end

  defp parse_files(paths) do
    Enum.map(paths, fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)
      Code.string_to_quoted(c)
    end)
  end
end
