# Meandro [![Build Status](https://github.com/AdRoll/meandro/actions/workflows/main.yml/badge.svg)](https://github.com/AdRoll/meandro) [![Hex pm](http://img.shields.io/hexpm/v/meandro.svg?style=flat)](https://hex.pm/packages/meandro)

## Find dead code in Elixir applications

![a spiraling oxbow lake, in the style of Salvador Dalí](https://repository-images.githubusercontent.com/517563597/31d745f4-5e0d-4680-97d2-d80e8d1c275e)

What kind of dead code? Meandro currently has rules to find:

- unused function arguments
- unused struct fields
- unused record fields
- unused configuration options
- unused callbacks
- unused macros

## Sample Output

If Meandro detects issues in your code, it will report them as follows…

```
lib/cache.ex:23 |> execute/1 doesn't need its #1 argument
lib/application.ex:15 |> maybe_evaluate/2 doesn't need its #1 argument
lib/application.ex:45 |> maybe_evaluate/3 doesn't need its #2 argument
Config files |> Configuration option :color (MIX_ENV=dev) is not used anywhere in the code
```

## Installation

The package can be installed [from hex](https://hex.pm/packages/meandro) by
adding `meandro` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:meandro, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/meandro](https://hexdocs.pm/meandro).

## Usage

```
mix meandro
```

is the basic command. It'll run all configured rules (which is all of them by default) against all of the `*.ex` files in your application.

You can pass the `--files` argument if you'd like to check only particular files.

```
mix meandro --files lib/foo.ex,lib/bar.ex
```

Be warned, however, that it will _only_ look at those files. Functions declared in those files but used elsewhere will be seen as "unused."

## Configuration

The plugin supports the following configuration options in the `meandro` section of `mix.exs`:

- `rules` (`[Meandro.Rule.t()]`):
  - This is the list of rules to apply to the analyzed code. Each rule is a module that should apply the `Meandro.Rule` behavior.
  - If this option is not defined, meandro will apply all of [the default rules](lib/meandro/rules).
- `parsing` (`Meandro.Util.parsing_style()`):
  - This parameter determines if meandro should parse files in a parallel (mapping through `Task.async/1`) or sequential (plain `Enum.map/2`) fashion.
  - The default value is `parallel` since it's faster.
- `ignore` (`[Path.t() | {Path.t(), Meandro.Rule.t() | [Meandro.Rule.t()]} | {Path.t(), Meandro.Rule.t() | [Meandro.Rule.t()], list()}]`):
  - List of wildcard patterns representing the files and rules that meandro will ignore when analyzing. Tuple format is used to ignore either a specific rule or a set of rules in those files.

### Example

```elixir
  def project do
    [
      meandro: meandro_config(),
      ...
    ]
  end

  def meandro_config() do
    %{
      rules: [Meandro.Rule.UnnecessaryFunctionArguments],
      parsing: :sequential,
      ignore: ["test/example.ex"]
    }
  end
```

