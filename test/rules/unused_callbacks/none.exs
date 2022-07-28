# There are no callbacks here
defmodule MeandroTest.MyBeh do
  # A regular function with a module as parameter
  def use(module) do
    module.used()
  end
end
