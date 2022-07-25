defmodule Mix.Tasks.Meandro do
  use Mix.Task

  @rules []

  # runs the task recursively in umbrella projects
  @recursive true

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

  @switches [
    remove: :boolean,
    files: :string
  ]

  @impl true
  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)

    files =
      parse_file_list(opts[:files], argv)
      |> ignore_files_from_config()

    asts = parse_files(files)

    # @todo handle rule parsing
    rules = @rules

    if opts[:remove] || false do
      Meandro.remove_dead_code(asts, rules)
      |> report_removal()
    else
      Meandro.search_dead_code(asts, rules)
      |> report_search()
    end
  end

  defp parse_file_list(nil, _), do: []

  defp parse_file_list(file, rest_of_files) do
    # Always try to split the `file` string. If it was a list of comma-separated
    # files we get a list with each file, and otherwise the single file is [wrapped]
    # in a list, allowing us to always `++/2` the list of files
    files = String.split(file, ",")
    files ++ rest_of_files
  end

  defp ignore_files_from_config(files) do
    # @todo read the `mix.exs` config and check if there are any file paths
    # we should append/use
    files
  end

  defp parse_files(files) do
    # @todo get the AST for all the files
    files
  end

  defp report_search(search_result) do
    Mix.shell().info(inspect(search_result))
  end

  defp report_removal(removal_result) do
    Mix.shell().info(inspect(removal_result))
  end
end
