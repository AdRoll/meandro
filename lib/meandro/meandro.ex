defmodule Meandro do
  # @todo add docs and @moduledoc
  @moduledoc """
  Documentation for `Meandro`.
  """

  # the IO.read/2 option changed from :all to :eof in Elixir 1.13
  # so Dialyzer doesn't like the old backwards compatibility mode in 1.13+
  @dialyzer {:no_fail_call, {:parse_files, 2}}

  @doc """
  Analyze
  """
  def analyze(files, _rules) do
    _asts = parse_files(files, :parallel)

    %{
      results: [],
      unused_ignores: [],
      stats: %{ignored: nil, parsing: nil, analyzing: nil, total: nil}
    }
  end

  defp parse_files(paths, :sequential) do
    Enum.map(paths, fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)
      Code.string_to_quoted(c)
    end)
  end

  defp parse_files(paths, :parallel) do
    fun = fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)
      Code.string_to_quoted(c)
    end

    paths
    |> Enum.map(&(Task.async(fn -> fun.(&1) end)))
    |> Enum.map(&Task.await/1)
  end
end
