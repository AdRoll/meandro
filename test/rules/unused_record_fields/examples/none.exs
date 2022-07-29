defmodule MeandroTest.Examples.UnusedRecordFields.None do
  @moduledoc "There are no records here"

  @doc "A regular function with a module as parameter"
  def use(module) do
    module.used()
  end
end
