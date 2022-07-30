defmodule MeandroTest.Rule.UnusedConfigurationOptions do
  use ExUnit.Case

  alias Meandro.Rule
  alias Meandro.Rule.UnusedConfigurationOptions

  @test_directory_path "test/rules/unused_configuration_options/examples/"

  test "warn about unused config options" do
    file = @test_directory_path <> "module.exs"
    files_and_asts = TestHelpers.parse_files([file])

    assert [
             %Rule{
               file: nil,
               line: 0,
               pattern: :other_unused_option,
               rule: UnusedConfigurationOptions,
               text:
                 "Configuration option :other_unused_option (MIX_ENV=test) is not used anywhere in the code"
             },
             %Rule{
               file: nil,
               line: 0,
               pattern: :unused_keyed_option,
               rule: UnusedConfigurationOptions,
               text:
                 "Configuration option :unused_keyed_option (MIX_ENV=test) is not used anywhere in the code"
             },
             %Rule{
               file: nil,
               line: 0,
               pattern: :unused_option,
               rule: UnusedConfigurationOptions,
               text:
                 "Configuration option :unused_option (MIX_ENV=test) is not used anywhere in the code"
             }
           ] =
             Rule.analyze(UnusedConfigurationOptions, files_and_asts,
               app: :meandro,
               mix_env: Mix.env()
             )
  end

  test "do not warn if Application.get_all_env(app) is used" do
    file1 = @test_directory_path <> "with_get_all_env.exs"
    file2 = @test_directory_path <> "module.exs"
    files_and_asts = TestHelpers.parse_files([file1, file2])

    assert [] =
             Rule.analyze(UnusedConfigurationOptions, files_and_asts,
               app: :meandro,
               mix_env: Mix.env()
             )
  end
end
