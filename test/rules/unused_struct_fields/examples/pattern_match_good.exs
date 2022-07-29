defmodule MeandroTest.Examples.UnusedStructFields.Source do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.Examples.UnusedStructFields.Source{
          lat: float,
          long: float
        }

  def test(%MeandroTest.Examples.UnusedStructFields.Source{lat: 1.1, long: 2.1}), do: true
end
