defmodule MeandroTest.MyBeh do
  @callback used(atom()) :: :res_used
  @callback used_incorrectly() :: :res_used_incorrectly

  # Uses a callback
  def use(module) do
    module.used(:with_an_atom)
  end

  defmodule MeandroTest.MyBehNested do
    def use(module) do
      # This is the right way
      MeandroTest.MyBeh.use(module)
      # This is the wrong way
      module.used_incorrectly()
    end
  end
end
