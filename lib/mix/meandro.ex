defmodule Mix.Tasks.Meandro do
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
  use Mix.Task

  @rules [:unused_callbacks]

  # runs the task recursively in umbrella projects
  @recursive true

  @shortdoc "Cleans dead code for you"
  @files_wildcard "**/*.{ex,exs}"

  @switches [
    files: :string
  ]

  @impl true
  def run(argv \\ []) do
    {opts, _parsed} = OptionParser.parse!(argv, strict: @switches)

    Mix.shell().info("Looking for code to kill with fire...")
    # TODO get all the rules dynamically
    rules = @rules
    Mix.shell().info("Meandro rules: #{inspect(rules)}")
    ## All files except those under _build or _checkouts
    files = get_files(Keyword.get(opts, :files))
    Mix.shell().info("Meandro will use #{length(files)} files for analysis: #{inspect(files)}")
    Meandro.analyze(files, rules)
  end

  defp get_files(files) when is_binary(files) do
    String.split(files, ",")
  end

  defp get_files(_) do
    Path.wildcard(@files_wildcard)
    |> Enum.reject(&is_hidden_name?/1)
  end

  defp is_hidden_name?(".") do
    false
  end

  defp is_hidden_name?("..") do
    false
  end

  defp is_hidden_name?("." <> _) do
    true
  end

  defp is_hidden_name?("_" <> _) do
    true
  end

  defp is_hidden_name?("deps/" <> _) do
    true
  end

  defp is_hidden_name?(_) do
    false
  end
end
