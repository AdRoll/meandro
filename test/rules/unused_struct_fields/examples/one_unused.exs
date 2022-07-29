defmodule MeandroTest.Examples.UnusedStructFields.OneUnused do
  defstruct [:lat, :long]

  @type t :: %MeandroTest.Examples.UnusedStructFields.OneUnused{
          lat: float,
          long: float
        }

  defp test do
    %MeandroTest.Examples.UnusedStructFields.OneUnused{long: 2.11}
  end
end
