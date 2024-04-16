defmodule Sketchy.GameRegistryTest do
  use ExUnit.Case

  alias Sketchy.Game
  alias Sketchy.GameRegistry

  @game_id "123"

  test "creates via registry name successfully" do
    via = GameRegistry.get_via(@game_id)

    assert via == {:via, Registry, {GameRegistry.name(), @game_id}}
  end

  test "returns Game pid registered with id successfully" do
    Game.start_link(%{id: @game_id})

    assert {:ok, _pid} = GameRegistry.get_pid(@game_id)
  end

  test "returns error if id not registered" do
    assert {:error, "game not found"} = GameRegistry.get_pid("abc")
  end
end
