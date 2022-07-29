defmodule MeandroTest.Examples.UnusedRecordFields.Exhaustive do
  require Record

  Record.defrecord(:spiderman,
    name: "Peter Parker",
    age: :it_depends,
    superpower: :spiders,
    is_cool?: true,
    is_made_of_spiders?: false,
    occupation: :journalist
  )

  def create_using_a_field do
    spiderman(name: "Miles Morales")
  end

  def get_a_field do
    spiderman(spiderman(), :superpower)
  end

  def update_a_field do
    spiderman(spiderman(), name: "Gwen Stacy", is_cool?: :heck_yeah)
  end

  def get_field_index do
    spiderman(:age)
  end

  def pattern_matched_field(record) do
    spiderman(is_made_of_spiders?: is_made_of_spiders?) = record
  end

  def pattern_matched_field_fun(spiderman(occupation: occupation)) do
    occupation
  end
end
