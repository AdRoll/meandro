# all callbacks are used here
defmodule MeandroTest.MyBeh do
  @callback used(atom()) :: :res_used
  @callback used_too(atom()) :: :res_used_too

  # Uses a callback
  def use(module) do
    IO.puts("something")
    module.used(:with_an_atom)
    Enum.map([:a, :b, :c], &module.used_too/1)
  end
end

defmodule MeandroTest.MyBehExtra do
  # just an extra module
end
