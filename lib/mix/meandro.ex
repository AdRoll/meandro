defmodule Mix.Tasks.Meandro do
  use Mix.Task

  @shortdoc "Cleans dead code for you"

  # @todo Add to the @moduledoc information about the rules meandro supports
  @moduledoc """
  `meandro` is a helper for dead code cleaning. It can assist you on searching
  for Oxbow code (dead code), and thus on keeping your application clean and tidy.

  Running this task will review your project, analyzing every *.ex[s] file in it
  (optionally skipping some folders/files if you want to - see below). Note that
  `meandro` will not consider files from your project dependencies for the analysis.
  It will only check the source code in your current application (applications, if
  you're working in an umbrella project).

  It will then apply its rules and produce a list of all the dead code (specially
  oxbow code) that you can effectively delete and/or refactor.
  """

  @impl Mix.Task
  def run([]), do: Mix.shell().error("No args were given")

  def run(args) do
    Mix.shell().info("Args: " <> Enum.join(args, " "))
  end
end
