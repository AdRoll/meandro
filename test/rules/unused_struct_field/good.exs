defmodule MeandroTest.MyStructTest do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyStructTest{
          lat: float,
          long: float
        }

  def test do
    unit = %MeandroTest.MyStructTest{lat: 1.1, long: 2.1}
  end
end
