defmodule MeandroTest.Examples.UnusedMacros.OneUsed do
  defmacro macro_a do
    quote do
      :used
    end
  end

  defmacro macro_b do
    quote do
      :used
    end
  end

  def test do
    result_b = MeandroTest.Examples.UnusedMacros.OneUsed.macro_b()
  end
end
