defmodule Rec do
  require Record
  Record.defrecord(:public_record, used: true, unused: :ok)
  Record.defrecordp(:priv_record, used: true, used_too: 1)

  def one_use(record) do
    public_record(record, :used)
  end

  def another_use(used?) do
    priv_record({PrivRecord, used?, used?}, :used)
    priv_record(used_too: 2)
  end
end
