defmodule FIDSTest do
  use ExUnit.Case
  doctest FIDS

  test "greets the world" do
    assert FIDS.hello() == :world
  end
end
