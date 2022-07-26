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
  It can be in `:parallel` or `:sequential` depending its second argument.
  """
  @spec parse_files([Path.t()], parsing_style()) :: [
          {Path.t(), [{atom(), Macro.t()}]}
        ]
  def parse_files(paths, :sequential) do
    Enum.map(paths, fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)

      Code.string_to_quoted!(c)
      |> maybe_split_by_module(p)
    end)
    |> List.flatten()
  end

  def parse_files(paths, :parallel) do
    fun = fn p ->
      f = File.open!(p)
      c = IO.read(f, :all)

      Code.string_to_quoted!(c)
      |> maybe_split_by_module(p)
    end

    paths
    |> Enum.map(&Task.async(fn -> fun.(&1) end))
    |> Enum.map(&Task.await/1)
    |> List.flatten()
  end

  defp maybe_split_by_module(ast, file) do
    {_, result} = Macro.prewalk(ast, [], &collect_modules/2)
    {file, result}
  end

  defp collect_modules({:defmodule, _, _} = module_node, acc) do
    {module_node, [{module_name(module_node), module_node} | acc]}
  end

  defp collect_modules(node, acc) do
    {node, acc}
  end

  @doc """
  Returns the module name given a module node AST
  """
  @spec module_name(Macro.t()) :: atom()
  def module_name({:defmodule, _, [{:__aliases__, _, aliases}, _]}) do
    Enum.map_join(aliases, ".", &Atom.to_string/1) |> String.to_atom()
  end
end
