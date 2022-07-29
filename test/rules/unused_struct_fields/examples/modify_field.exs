defmodule MeandroTest.MyStructTest do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyStructTest{
          lat: float,
          long: float
        }

  defp test do
    st = %MeandroTest.MyStructTest{long: 2.11}
    %{st | lat: 1.10}
  end
end
