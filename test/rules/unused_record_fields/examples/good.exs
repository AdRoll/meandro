defmodule MeandroTest.Examples.UnusedRecordFields.Good do
  require Record
  Record.defrecord(:public_record, used: true, used_too: true)

  def use(record) do
    public_record(record, :used) || public_record(record, :used_too)
  end
end
