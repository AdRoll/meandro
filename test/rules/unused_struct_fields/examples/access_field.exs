defmodule MeandroTest.MyStructTest do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyStructTest{
          lat: float,
          long: float
        }

  defp test do
    st = %MeandroTest.MyStructTest{}
    latitude = st.lat
    longitude = st.long
  end
end
