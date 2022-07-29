# all callbacks are used here
defmodule MeandroTest.Examples.UnusedCallbacks.Multi do
  @callback used_twice(atom()) :: :res_used
  @callback used_only_once(atom()) :: :res_used_only_once

  # Uses a callback
  def use(module) do
    module.used_twice(:with_an_atom)
    Enum.map([:a, :b, :c], &module.used_only_once/1)
  end
end

# same callbacks, but only one is used here
defmodule MeandroTest.Examples.UnusedCallbacks.Multi.Extra do
  @callback used_twice(atom()) :: :res_used
  @callback used_only_once(atom()) :: :res_used_only_once

  # Uses a callback
  def use(module) do
    module.used_twice(:with_an_atom)
    MeandroTest.Multi.use(module)
  end
end
