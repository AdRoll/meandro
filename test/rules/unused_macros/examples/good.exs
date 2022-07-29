defmodule MeandroTest.Examples.UnusedMacros.Good do
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
    result_a = macro_a()
    result_b = MeandroTest.Examples.UnusedMacros.Good.macro_b()
  end
end
