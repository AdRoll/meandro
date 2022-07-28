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
  Oxbow code) that you can effectively delete and/or refactor.

  `meandro` accepts the following CLI options:
    - `--files` - overrides the list of files to analyze (defaults to all the files
      in your application(s), or whatever is configured otherwise in your `mix.exs` file).
      It can be:
        - a path to a single file (`--files lib/your_module.ex`),
        - a list of comma-separated files (`--files lib/your_module.ex,lib/your_other_module.ex`),
        - or a path to a folder with an expansion (`--files lib/*`).
    - `--parsing` - defines how to parse the files (`sequentially` or `parallel`, defaults to `parallel`).

  `meandro` can also be configured from the `mix.exs` file of your application. It accepts the following
  configuration values:
  ### @todo TBA when the config parsing is in place
  """
  use Mix.Task

  # runs the task recursively in umbrella projects
  @recursive true

  @shortdoc "Identifies dead code for you"
  @files_wildcard "**/*.{ex,exs}"
  @rules_wildcard "lib/meandro/rules/*.ex"

  @switches [
    files: :string,
    parsing: :string
  ]

  @impl true
  def run(argv \\ []) do
    {parsed, rest} = OptionParser.parse!(argv, strict: @switches)

    Mix.shell().info("Looking for oxbow lakes to dry up...")

    rules =
      for file <- Path.wildcard(@rules_wildcard),
          do: Meandro.Util.module_name_from_file_path(file)

    Mix.shell().info("Meandro rules: #{inspect(rules)}")

    ## All files except those under _build or _checkouts
    files = get_files(parsed[:files], rest)

    parsing_style =
      Keyword.get(parsed, :parsing, "parallel")
      |> String.to_existing_atom()

    Mix.shell().info("Meandro will use #{length(files)} files for analysis: #{inspect(files)}")

    result = Meandro.analyze(files, rules, parsing_style)
    result_str = Kernel.inspect(result, pretty: true)

    IO.puts("Meandro obtained the following results: #{result_str}")
    result
  end

  defp get_files(files, rest_of_files) when is_binary(files) do
    String.split(files, ",") ++ rest_of_files
  end

  defp get_files(_, _) do
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

  # there are cases like the node_modules phoenix dep with .ex inside
  defp is_hidden_name?("node_modules/" <> _) do
    true
  end

  defp is_hidden_name?(_) do
    false
  end
end
