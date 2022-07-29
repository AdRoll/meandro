defmodule Meandro.Rule do
  @moduledoc """
  Module that defines the behaviour that `Meandro`'s rules will
  implement.
  """

  defstruct [:module, :file, :line, :text, :rule, :pattern]

  @type t() :: :undefined | module()

  @type asts() :: [{Path.t(), Macro.t()}]

  @typedoc """
  Piece of oxbow code detection on applying a Meandro rule.
  """
  @type result() :: %Meandro.Rule{
          file: Path.t(),
          line: non_neg_integer(),
          text: charlist(),
          rule: t(),
          pattern: ignore_pattern(),
          module: module()
        }

  @type ignore_pattern() :: :undefined | tuple()

  @type ignore_spec() :: {Path.t(), t() | :all} | {Path.t(), t(), term()}

  @callback analyze(asts(), term()) :: [result()]

  @callback is_ignored?(ignore_pattern(), term()) :: boolean()

  @spec analyze(rule_mod :: module(), asts :: asts(), context :: keyword()) :: [result()]
  def analyze(rule_mod, asts, context) do
    for result <- rule_mod.analyze(asts, context),
        do: %Meandro.Rule{result | rule: rule_mod}
  end
end
