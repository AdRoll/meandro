defmodule MeandroTest.Examples.UnusedRecordFields.Multi.Definition do
  require Record

  Record.defrecord(:abc, field: :value)
end

defmodule MeandroTest.Examples.UnusedRecordFields.Multi.Usage do
  import DefinesRecord

  def use do
    record = abc()
    record(:field)
  end
end
