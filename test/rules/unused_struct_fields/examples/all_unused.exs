defmodule MeandroTest.Examples.UnusedStructFields.Unused do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.Examples.UnusedStructFields.Unused{
          lat: float,
          long: float
        }
end
