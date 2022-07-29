defmodule MeandroTest.Examples.UnusedMacros.DifferentArity do
  defmacro macro_a do
    quote do
      :used
    end
  end

  defmacro macro_a(arga) do
    quote do
      :used
    end
  end

  defmacro macro_a(arga, argb) do
    quote do
      :first_arg
    end
  end

  def test do
    macro_a("hey")
  end
end
