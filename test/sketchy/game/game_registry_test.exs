defmodule Sketchy.Game.GameRegistryTest do
  use ExUnit.Case

  alias Sketchy.Game.Server, as: Game
  alias Sketchy.Game.GameRegistry

  @game_id "123"

  test "creates via registry name successfully" do
    via = GameRegistry.get_via(@game_id)

    assert via == {:via, Registry, {GameRegistry.name(), @game_id}}
  end

  test "returns Game pid registered with id successfully" do
    start_supervised!({Game, %{id: @game_id}})

    assert {:ok, _pid} = GameRegistry.get_pid(@game_id)
  end

  test "returns error if id not registered" do
    assert {:error, "game not found"} = GameRegistry.get_pid("abc")
  end
end
