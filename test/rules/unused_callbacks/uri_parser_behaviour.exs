# Taken from https://hexdocs.pm/elixir/1.12.3/Module.html#module-behaviour
defmodule MeandroTest.URI.Parser do
  @doc "Defines a default port"
  @callback default_port() :: integer

  @doc "Parses the given URL"
  @callback parse(uri_info :: URI.t()) :: URI.t()
end
