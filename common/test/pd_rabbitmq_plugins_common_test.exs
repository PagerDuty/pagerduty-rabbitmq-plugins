defmodule PdRabbitmqPluginsCommonTest do
  use ExUnit.Case
  doctest PdRabbitmqPluginsCommon

  test "greets the world" do
    assert PdRabbitmqPluginsCommon.hello() == :world
  end
end
