# Taken from https://hexdocs.pm/elixir/1.12.3/Module.html#module-behaviour
defmodule MeandroTest.URI.HTTP do
  @behaviour MeandroTest.URI.Parser
  def default_port(), do: 80
  def parse(info), do: info
end
