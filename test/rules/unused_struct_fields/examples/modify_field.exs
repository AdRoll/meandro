defmodule MeandroTest.Examples.UnusedStructFields.Modify do
  defstruct [:lat, long: 0]

  @type t :: %MeandroTest.Examples.UnusedStructFields.Modify{
          lat: float,
          long: float
        }

  defp test do
    st = %MeandroTest.Examples.UnusedStructFields.Modify{long: 2.11}
    %{st | lat: 1.10}
  end
end
