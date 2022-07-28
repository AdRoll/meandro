defmodule MeandroTest.Rule.UnusedConfigurationOptions do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedConfigurationOptions

  #@test_directory_path "test/rules/unused_configuration_options/"

  test "warns about unused config options" do
    # file = @test_directory_path <> "module.exs"
    # module = read_module_name(file)
    # files_and_asts = TestHelpers.parse_files([file])
    # expected_text1 = "unused_option is not used anywhere in the code"
    # expected_text2 = "other_unused_option is not used anywhere in the code"

    # assert [
    #          %Meandro.Rule{
    #            file: ^file,
    #            line: 0,
    #            pattern: {:unused_option, 0},
    #            rule: Meandro.Rule.UnusedConfigurationOptions,
    #            text: ^expected_text1
    #          },
    #          %Meandro.Rule{
    #            file: @test_directory_path <> "module.exs",
    #            line: 0,
    #            pattern: {:other_unused_option, 0},
    #            rule: Meandro.Rule.UnusedConfigurationOptions,
    #            text: ^expected_text2
    #          }
    #        ] = Meandro.Rule.analyze(UnusedConfigurationOptions, files_and_asts, :nocontext)
  end
end
