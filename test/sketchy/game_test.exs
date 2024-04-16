defmodule Sketchy.GameTest do
  use ExUnit.Case

  alias Sketchy.Game

  setup do
    {:ok, pid} = Game.start_link(%{id: "123"})

    %{pid: pid}
  end

  test "game is created with initial state", %{pid: pid} do
    state = Game.get_game_state(pid)

    assert %{
             id: "123",
             status: "pending",
             active_user: nil,
             users: []
           } = state
  end

  test "join adds user to state.users with guessed=false", %{pid: pid} do
    new_user = %{
      name: "Bob",
      id: "abc"
    }

    Game.join(pid, new_user)

    %{users: users} = Game.get_game_state(pid)

    assert users == [Map.put(new_user, :guessed, false)]
  end
end
