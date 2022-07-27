defmodule MeandroTest.MyBeh do

  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyBeh{
          lat: float,
          long: float
        }

  defp test() do
    %MeandroTest.MyBeh{long: 2.11}
  end
end
