defmodule MeandroRule do
  @moduledoc """
  Module that defines the behaviour that `meandro`'s rules will
  implement.
  """

  defstruct file: "", line: 0, text: "", rule: :undefined, pattern: :undefined

  @type t() :: :undefined | module()

  @type asts() :: [{Path.t(), Macro.t()}]

  @type result() :: %MeandroRule{
          file: Path.t(),
          line: non_neg_integer(),
          text: charlist(),
          rule: t(),
          pattern: ignore_pattern()
        }

  @type ignore_pattern() :: :undefined | tuple()

  @type ignore_spec() :: {Path.t(), t() | :all} | {Path.t(), t(), term()}

  @callback analyze(asts(), term()) :: [result()]

  @callback ignored(ignore_pattern(), term()) :: boolean()

  def analyze(rule_mod, asts, context) do
    for result <- rule_mod.analyze(asts, context),
        do: %MeandroRule{result | rule: rule_mod}
  rescue
    x ->
      Mix.raise("#{inspect(rule_mod)}:analyze/3 failed: #{inspect(x)}")
  end
end
