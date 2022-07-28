defmodule Meandro.Util do
  @moduledoc """
  Utilitary functions for the library as a whole
  """

  @typedoc """
  parsing_style will instruct Meandro to compute the rules in parallel or sequentially.
  """
  @type parsing_style() :: :sequential | :parallel

  @doc """
  Reads the `paths` and returns their AST as `{file, AST}` tuples.
  It can be in `:parallel` or `:sequential` depending its second argument.
  """
  @spec parse_files([Path.t()], parsing_style()) :: [
          {Path.t(), [{module(), Macro.t()}]}
        ]
  def parse_files(paths, :sequential) do
    paths
    |> Enum.map(&file_to_ast/1)
    |> List.flatten()
  end

  def parse_files(paths, :parallel) do
    paths
    |> Enum.map(&Task.async(fn -> file_to_ast(&1) end))
    |> Enum.map(&Task.await/1)
    |> List.flatten()
  end

  defp file_to_ast(file) do
    file
    |> File.read!()
    |> Code.string_to_quoted!()
    |> maybe_split_by_module(file)
  end

  defp maybe_split_by_module(ast, file) do
    {_, {_, result}} = Macro.prewalk(ast, {file, []}, &collect_modules/2)
    {file, result}
  end

  defp collect_modules({:defmodule, _, params} = module_node, {file, acc}) do
    case params do
      [{:__aliases__, _, _} | _] ->
        {module_node, {file, acc ++ [{module_name(module_node), module_node}]}}

      _ ->
        # @todo cry and fix this
        # try your luck at parsing https://github.com/bencheeorg/benchee/blob/main/lib/benchee.ex
        Mix.shell().error(
          "Meandro had to ignore file '#{file}' due to its unexpectedly formed AST"
        )

        {module_node, {file, acc}}
    end
  end

  defp collect_modules(node, acc) do
    {node, acc}
  end

  @doc """
  Returns the module name given a module node AST
  """
  @spec module_name(Macro.t()) :: atom()
  def module_name({:defmodule, _, [{:__aliases__, _, aliases}, _]}) do
    ast_module_name_to_atom(aliases)
  end

  @spec ast_module_name_to_atom([atom()]) :: atom()
  def ast_module_name_to_atom(aliases) do
    aliases |> Enum.map_join(".", &Atom.to_string/1) |> String.to_atom()
  end

  @doc """
  Returns the module aliases
  """
  @spec module_aliases(Macro.t()) :: Macro.t()
  def module_aliases(ast) do
    {_, aliases} = Macro.prewalk(ast, nil, &get_module_aliases/2)
    aliases
  end

  def functions(ast) do
    {_, functions} = Macro.prewalk(ast, [], &get_functions/2)
    functions
  end

  defp get_module_aliases({:defmodule, _, [{:__aliases__, _, aliases}, _]} = ast, _) do
    {ast, aliases}
  end

  defp get_module_aliases(other, aliases) do
    {other, aliases}
  end

  defp get_functions({:def, _, _} = function, functions) do
    {function, [function | functions]}
  end

  defp get_functions({:defp, _, _} = function, functions) do
    {function, [function | functions]}
  end

  defp get_functions(ast, functions) do
    {ast, functions}
  end
end
