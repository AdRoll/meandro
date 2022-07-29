defmodule MeandroTest.Examples.UnusedRecordFields.Extract do
  require Record
  Record.defrecord(:a_record, Record.extract(:a_record, from_lib: "a_header_file.hrl"))
end
