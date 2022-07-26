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
  def analyze(files, _rules, parsing_style) do
    _files_and_asts = parse_files(files, parsing_style)

    %{
      results: [],
      unused_ignores: [],
      stats: %{ignored: nil, parsing: nil, analyzing: nil, total: nil}
    }
  end

  @spec parse_files(paths :: [Path.t()], parsing_style :: :sequential | :parallel) :: [
          {Path.t(), Macro.t()}
        ]
  defp parse_files(paths, :sequential) do
    Enum.map(paths, fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)
      ast = Code.string_to_quoted!(c)
      {p, ast}
    end)
  end

  defp parse_files(paths, :parallel) do
    fun = fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)
      ast = Code.string_to_quoted!(c)
      {p, ast}
    end

    paths
    |> Enum.map(&Task.async(fn -> fun.(&1) end))
    |> Enum.map(&Task.await/1)
  end
end
