defmodule MeandroTest.UnusedConfigurationOptions.Module do
  # a function that returns a config option
  def some_fun() do
    Application.get_env(:meandro, :used_option)
    other_fun(Application.fetch_env!(:meandro, :input_key_option))
  end

  def other_fun(key) do
    [
      key,
      Application.fetch_env(:meandro, :nice_option),
      # calls get_all_env from other app -> ignore it!
      Application.get_all_env(:other_app),
      # calls to an unused option but from other app -> ignore it!
      Application.fetch_env(:other_app, :unused_option),
      # uses a keyed option also
      Application.get_env(:meandro, :used_keyed_option)
    ]
  end
end
