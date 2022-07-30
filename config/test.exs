import Config

config :meandro,
  used_option: "value1",
  unused_option: "value2",
  other_unused_option: "value3",
  input_key_option: :ok,
  nice_option: :nice

config :meandro, MeandroTest.UnusedConfigurationOptions.Module,
  used_keyed_option: "value1",
  unused_keyed_option: "value2"
