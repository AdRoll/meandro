defmodule MeandroTest.MyBeh do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyBeh{
          lat: float,
          long: float
        }

  defp test do
    st = %MeandroTest.MyBeh{}
    latitude = st.lat
    longitude = st.long
  end
end
