defmodule Meandro.Util do
  @moduledoc """
  Utilitary functions for the library as a whole
  """
  # the IO.read/2 option changed from :all to :eof in Elixir 1.13
  # so Dialyzer doesn't like the old backwards compatibility mode in 1.13+
  @dialyzer {:no_fail_call, {:parse_files, 2}}

  @typedoc """
  parsing_style will instruct Meandro to compute the rules in parallel or sequentially.
  """
  @type parsing_style() :: :sequential | :parallel

  @doc """
  Reads the `paths` and returns their AST as `{file, AST}` tuples.
  It can be in `:parallel` or `:squential` depending its second argument.
  """
  @spec parse_files([Path.t()], parsing_style()) :: [
          {Path.t(), Macro.t()}
        ]
  def parse_files(paths, :sequential) do
    Enum.map(paths, fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)
      ast = Code.string_to_quoted!(c)
      {p, ast}
    end)
  end

  def parse_files(paths, :parallel) do
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
