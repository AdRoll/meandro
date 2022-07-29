defmodule DefinesRecord do
  require Record

  Record.defrecord(:abc, field: :value)
end

defmodule UsesRecord do
  import DefinesRecord

  def use do
    record = abc()
    abc(:field)
  end
end
