defmodule MeandroTest.Examples.Ignores.OneIgnored do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.Examples.Ignores.SeveralIgnored{
          lat: float,
          long: float
        }

  @meandro [
    ignore: {Meandro.Rule.UnusedStructFields, {:"MeandroTest.Examples.Ignores.OneIgnored", :lat}}
  ]
  defp test do
    %MeandroTest.Examples.Ignores.OneIgnored{long: 2.11}
  end
end
