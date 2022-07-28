ExUnit.start()

defmodule TestHelpers do
  def parse_files(files, parsing_style \\ :sequential) do
    Meandro.Util.parse_files(files, parsing_style)
  end

  def read_module_name(file_path) do
    {:ok, contents} = File.read(file_path)
    pattern = ~r{defmodule \s+ ([^\s]+) }x

    Regex.scan(pattern, contents, capture: :all_but_first)
    |> List.flatten()
    |> List.first()
    |> String.to_atom()
  end
end
