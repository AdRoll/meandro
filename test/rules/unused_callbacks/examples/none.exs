defmodule MeandroTest.Examples.UnusedCallbacks.None do
  @moduledoc "There are no callbacks here"

  @doc "A regular function with a module as parameter"
  def use(module) do
    module.used()
  end
end
