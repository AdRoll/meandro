defmodule MeandroTest.MyBeh do

  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyBeh{
          lat: float,
          long: float
        }
end
