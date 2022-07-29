defmodule MeandroTest.Examples.UnusedCallbacks.Good do
  @moduledoc "all callbacks are used here"
  @callback used(atom()) :: :res_used
  @callback used_too(atom()) :: :res_used_too

  # Uses a callback
  def use(module) do
    IO.puts("something")
    module.used(:with_an_atom)
    Enum.map([:a, :b, :c], &module.used_too/1)
  end
end

defmodule MeandroTest.Examples.UnusedCallbacks.Good.Extra do
  @moduledoc "Just an extra module"
end
