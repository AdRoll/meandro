defmodule MeandroTest.UFA.MyBeh do
  @moduledoc "MyBeh definition"
  @callback a_callback(any()) :: tuple()
  @callback another_callback(any()) :: tuple()
end

defmodule MeandroTest.UFA.MyImpl do
  @moduledoc "MyBeh implementation"

  alias MeandroTest.UFA.MyBeh
  @behaviour MyBeh

  @impl MyBeh
  @spec a_callback(any()) :: tuple()
  def a_callback(_), do: {:shouldnt, :warn, :here, :since, "it is a callback"}

  def another_callback(_), do: {:should, :warn, :because_of, :no, "@impl"}

  @impl MyBeh
  def dynamic_callback(_), do: {:like, :the, :ones, :in, :gen_statem}

  def warn(_), do: "Should warn about the unused parameter"
end
