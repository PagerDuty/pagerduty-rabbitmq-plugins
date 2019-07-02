defmodule PdEventsApiPluginTest do
  use ExUnit.Case
  doctest PdEventsApiPlugin

  test "greets the world" do
    assert PdEventsApiPlugin.hello() == :world
  end
end
