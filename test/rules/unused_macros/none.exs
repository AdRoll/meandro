defmodule MeandroTest.MyMacroTest do
  # A regular function with a module as parameter
  def use(module) do
    module.used()
  end
end
