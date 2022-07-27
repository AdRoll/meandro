defmodule MeandroTest.MyBeh do

  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyBeh{
          lat: float,
          long: float
        }

  defp test() do
    st = %MeandroTest.MyBeh{long: 2.11}
    %{st | lat: 1.10}
  end
end
