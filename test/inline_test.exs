defmodule InlineTest do
  use ExUnit.Case
  doctest Inline

  test "greets the world" do
    assert Inline.hello() == :world
  end
end
