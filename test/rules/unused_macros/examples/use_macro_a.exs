defmodule MeandroTest.Examples.UnusedMacros.UseMacroA do
  def test do
    MeandroTest.Examples.UnusedMacros.DifferentArity.macro_a()
    MeandroTest.Examples.UnusedMacros.OneUsed.macro_a()
  end
end
