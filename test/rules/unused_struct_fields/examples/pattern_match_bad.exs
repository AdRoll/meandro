defmodule MeandroTest.MyStructTest do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyStructTest{
          lat: float,
          long: float
        }

  def test(%MeandroTest.MyStructTest{lat: 1.1}), do: true
end
