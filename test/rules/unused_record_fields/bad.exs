defmodule Rec do
  require Record
  Record.defrecord(:public_record, unused: true, unused_too: true)

  def hello do
    :hello_world
  end
end
