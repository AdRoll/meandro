defmodule Meandro.MyImpl do
  @moduledoc "A gen_statem implementation"

  @behaviour :gen_statem

  @impl :gen_statem
  def my_state(_event_type, _old_state, data), do: {:next_state, :other_state, data}

  @impl :gen_statem
  def callback_mode, do: [:state_functions, :state_enter]

  @impl :gen_statem
  def init(_), do: {:ok, :my_state, :data}
end
