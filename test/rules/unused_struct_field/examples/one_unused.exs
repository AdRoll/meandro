defmodule MeandroTest.MyStructTest do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyStructTest{
          lat: float,
          long: float
        }

  defp test do
    %MeandroTest.MyStructTest{long: 2.11}
  end
end
