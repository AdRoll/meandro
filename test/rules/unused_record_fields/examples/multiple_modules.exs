defmodule MeandroTest.Examples.UnusedRecordFields.Multi.Definition do
  require Record

  Record.defrecord(:abc, field: :value)
end

defmodule MeandroTest.Examples.UnusedRecordFields.Multi.Usage do
  import MeandroTest.Examples.UnusedRecordFields.Multi.Definition

  def use do
    record = abc()
    abc(:field)
  end
end
