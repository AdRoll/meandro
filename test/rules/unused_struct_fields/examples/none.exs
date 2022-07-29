defmodule MeandroTest.Examples.UnusedStructFields.None do
  @doc "A regular function with a module as parameter"
  def use(module) do
    module.used()
  end
end
