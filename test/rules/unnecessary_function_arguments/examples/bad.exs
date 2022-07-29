defmodule MeandroTest.Examples.UnnecessaryFunctionArguments.Bad do
  @moduledoc "Some arguments are unused"

  @doc "One argument, one clause"
  def ignore(_this_argument), do: :ignored

  @doc "Two arguments, one clause, one arg is ignored"
  def ignore(the_second, _argument), do: {the_second, :is, :ignored}

  @doc "Two arguments, two clauses, one arg is ignored"
  def also_ignore(the_second, _argument) when is_atom(the_second) do
    {the_second, :argument, :is, :ignored}
  end

  def also_ignore(_, _), do: "All arguments ignored in this clause"

  @doc "Private function"
  defp private("function", _with, _two, :args, {:ignored, ignored}) do
    {2, :args, :are, ignored}
  end

  defp private(:second_clause, _with, _more, _ignored, _args) do
    {4, :args, :are, :ignored}
  end
end
