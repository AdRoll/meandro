defmodule MeandroTest.Examples.UnusedCallbacks.Parent do
  @callback used(atom()) :: :res_used
  @callback used_incorrectly() :: :res_used_incorrectly

  # Uses a callback
  def use(module) do
    module.used(:with_an_atom)
  end

  defmodule MeandroTest.Examples.UnusedCallbacks.Nested do
    def use(module) do
      # This is the right way
      MeandroTest.Nested.use(module)
      # This is the wrong way
      module.used_incorrectly()
    end
  end
end
