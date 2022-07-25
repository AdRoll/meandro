defmodule Meandro do
  # @todo add docs and @moduledoc
  @moduledoc """
  Documentation for `Meandro`.
  """

  # the IO.read/2 option changed from :all to :eof in Elixir 1.13
  # so Dialyzer doesn't like the old backwards compatibility mode in 1.13+
  @dialyzer {:no_fail_call, {:parse_files, 1}}

  @doc """
  Analyze
  """
  def analyze(files, _rules) do
    _asts = parse_files(files)

    %{
      results: [],
      unused_ignores: [],
      stats: %{ignored: nil, parsing: nil, analyzing: nil, total: nil}
    }
  end

  defp parse_files(paths) do
    Enum.map(paths, fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)
      Code.string_to_quoted(c)
    end)
  end
end
