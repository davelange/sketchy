defmodule Sketchy.Game.ServerTest do
  use ExUnit.Case, async: true

  alias Sketchy.Game.Users
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
             active_user_id: nil,
             users: []
           } = state
  end

  test "join adds user to state.users", %{pid: pid} do
    new_user = Users.create("bob")

    Game.join(pid, new_user)

    %{users: users} = Game.get_state(pid)

    assert users == [new_user]
  end

  test "leave removes user from state.users", %{pid: pid} do
    bob = Users.create("bob")
    alice = Users.create("alice")

    Game.join(pid, bob)
    Game.join(pid, alice)
    Game.leave(pid, bob.id)

    %{users: users} = Game.get_state(pid)

    assert users == [alice]
  end

  test "turn ends after turn_duration passes, then moves to next turn after inter_turn_duration",
       %{pid: pid} do
    bob = Users.create("bob")
    alice = Users.create("alice")

    secret_word = "banana"

    Game.join(pid, bob)
    Game.join(pid, alice)
    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => secret_word})

    Process.sleep(15)
    assert %{state: "turn_over"} = Game.get_state(pid)

    Process.sleep(15)
    assert %{state: "turn_pending"} = Game.get_state(pid)
  end
end
