defmodule MeandroTest.Examples.UnusedStructFields.Access do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.Examples.UnusedStructFields.Access{
          lat: float,
          long: float
        }

  defp test do
    st = %MeandroTest.Examples.UnusedStructFields.Access{}
    latitude = st.lat
    longitude = st.long
  end
end
