# `unused/0` is an unused callback
defmodule MeandroTest.Examples.UnusedCallbacks.Bad do
  @callback used(atom()) :: :res_used
  @callback used_too(atom()) :: :res_used_too
  @callback unused :: :res_unused
  @callback unused_too() :: :res_unused_too

  # Uses a callback
  def use(module) do
    IO.puts("something")
    module.used(:with_an_atom)
    Enum.map([:a, :b, :c], &module.used_too/1)
  end

  defmodule MeandroTest.Examples.UnusedCallbacks.Bad.Nested do
    @moduledoc "just a submodule"
  end
end
