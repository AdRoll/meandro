defmodule Rec do
  require Record
  Record.defrecord(:public_record, used: true, used_too: true)

  def hello do
    :hello_world
  end
end
