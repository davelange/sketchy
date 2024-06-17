defmodule Sketchy.Game.ServerTest do
  use ExUnit.Case, async: true

  alias Sketchy.Game.Players
  alias Sketchy.Game.Server, as: Game

  setup do
    pid =
      start_supervised!(%{
        id: {Game, []},
        start: {Game, :start_link, [%{id: "123", inter_turn_duration: 10, turn_duration: 10}]},
        restart: :transient
      })

    %{pid: pid}
  end

  test "game is created with initial state", %{pid: pid} do
    state = Game.get_state(pid)

    assert %{
             id: "123",
             state: "pending",
             players: []
           } = state
  end

  test "join adds user to state.users", %{pid: pid} do
    new_user = Players.create("bob")

    Game.join(pid, new_user)

    %{players: users} = Game.get_state(pid)

    assert users == [new_user]
  end

  test "leave removes user from state.users", %{pid: pid} do
    bob = Players.create("bob")
    alice = Players.create("alice")

    Game.join(pid, bob)
    Game.join(pid, alice)
    Game.leave(pid, bob.id)

    %{players: users} = Game.get_state(pid)

    assert users == [alice]
  end
end
