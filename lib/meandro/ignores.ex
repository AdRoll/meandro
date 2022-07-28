defmodule Meandro.Ignore do
  @moduledoc """
  Meandro ignore logic
  """

  defstruct [:file, :module, :pattern]

  @type t :: %Meandro.Ignore{
          file: String.t(),
          module: module,
          pattern: term
        }

  def ignores(files_and_asts) do
    for {file, module_asts} <- files_and_asts,
        {_module_name, ast} <- module_asts,
        result <- ignores_in_module(file, ast) do
      result
    end
  end

  def ignores_in_module(file, ast) do

  end

end
