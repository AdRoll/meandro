defmodule MeandroTest.MyMacroTest do
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
    result_a = macro_a()

    macro_a("hey")
  end
end
