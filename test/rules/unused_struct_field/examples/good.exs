defmodule MeandroTest.Examples.UnusedStructFields.Good do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.Examples.UnusedStructFields.Good{
          lat: float,
          long: float
        }

  def test do
    unit = %MeandroTest.Examples.UnusedStructFields.Good{lat: 1.1, long: 2.1}
  end
end
