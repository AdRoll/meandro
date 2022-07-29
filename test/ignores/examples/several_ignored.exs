defmodule MeandroTest.Examples.Ignores.SeveralIgnored  do
  @callback used(atom()) :: :res_used
  @callback used_too(atom()) :: :res_used_too
  @meandro [ignore: {Meandro.Rule.UnusedCallbacks, {:unused, 0}}]
  @callback unused() :: :res_unused
  @meandro [ignore: {Meandro.Rule.UnusedCallbacks, :unused_too}]
  @callback unused_too() :: :res_unused_too

  @meandro [ignore: {Meandro.Rule.UnusedMacros, {:macro_a, 0}}]
  defmacro macro_a do
    quote do
      :used
    end
  end

  # Uses a callback
  def use(module) do
    IO.puts("something")
    module.used(:with_an_atom)
    Enum.map([:a, :b, :c], &module.used_too/1)
  end

  defmodule MeandroTest.BadNested do
    @moduledoc "just a submodule"
  end
end
