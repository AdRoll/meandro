defmodule MeandroTest do
  use ExUnit.Case
  doctest Meandro

  test "greets the world" do
    assert Meandro.hello() == :world
  end
end
