defmodule MeandroTest.MyBeh do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.MyBeh{
          lat: float,
          long: float
        }

  def test() do
    unit = %MeandroTest.MyBeh{lat: 1.1, long: 2.1}
  end
end
