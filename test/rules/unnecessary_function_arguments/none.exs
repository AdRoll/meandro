@doc "There are no function arguments here here"
defmodule MeandroTest.UFA.None do
  @doc "A regular function with no arguments"
  def public do
    :no_args
  end

  @doc "A private function with no arguments"
  defp private do
    :no_args
  end
end
