defmodule Mix.Tasks.Meandro do
  @moduledoc "Printed when the user requests `mix help meandro`"
  @shortdoc "WIP Meandro"

  use Mix.Task

  @impl Mix.Task
  def run([]), do: Mix.shell().error("No args were given")

  def run(args) do
    Mix.shell().info("Args: " <> Enum.join(args, " "))
  end
end
