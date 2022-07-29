defmodule MeandroTest.Examples.UnusedRecordFields.BadMulti do
  require Record
  Record.defrecord(:public_record, unused: true)
  Record.defrecordp(:priv_record, unused_too: true)

  def hello do
    :hello_world
  end
end
