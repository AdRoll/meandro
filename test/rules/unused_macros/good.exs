defmodule MeandroTest.MyMacroTest do

  defmacro unused do
    quote do
      :unused
    end
  end

end
