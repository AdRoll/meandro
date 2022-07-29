defmodule MeandroTest.UnusedConfigurationOptions.WithGetAllEnv do
  # a function that returns a config option
  def some_fun() do
    Application.get_all_env(:meandro)
  end
end
