@doc "all function arguments are necessary here"
defmodule MeandroTest.UFA.Good do
  @doc "One argument, one clause"
  def one_one(arg1), do: arg1

  @doc "Two arguments, one clause"
  def two_one(arg1, arg2) do
    arg1 + arg2
  end

  @doc "One argument, two clauses"
  def one_two(arg1) when is_binary(arg1), do: "Arg1 is " <> arg1
  def one_two(_) when is_binary(arg2), do: "Arg1 is ignored"

  @doc "Two arguments, two clauses"
  defp two_two(arg1, arg2) when is_binary(arg2), do: "Arg2 is only used in guards " <> arg1

  defp two_two(arg1, arg2) when is_binary(arg1), is_atom(arg2) do
    "All args only used in guards"
  end

  defp with_integer(0), do: "argument is an integer"
  defp with_string("boo"), do: "argument is a string"
end
