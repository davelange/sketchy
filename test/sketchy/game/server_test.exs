defmodule Sketchy.Game.ServerTest do
  use ExUnit.Case, async: true

  alias Sketchy.TestHelpers
  alias Sketchy.Game.Server, as: Game

  setup do
    pid =
      start_supervised!(%{
        id: {Game, []},
        start: {Game, :start_link, [%{id: "123"}]},
        restart: :transient
      })

    %{pid: pid}
  end

  test "game is created with initial state", %{pid: pid} do
    state = Game.get_state(pid)

    assert %{
             id: "123",
             status: "pending",
             active_user: nil,
             users: []
           } = state
  end

  test "join adds user to state.users", %{pid: pid} do
    new_user = %{
      name: "Bob",
      id: "abc",
      guessed: false
    }

    Game.join(pid, new_user)

    %{users: users} = Game.get_state(pid)

    assert users == [new_user]
  end

  test "leave removes user from state.users", %{pid: pid} do
    bob = %{
      name: "Bob",
      id: "abc",
      guessed: false
    }

    alice = %{
      name: "Alice",
      id: "alice",
      guessed: false
    }

    Game.join(pid, bob)
    Game.join(pid, alice)
    Game.leave(pid, bob.id)

    %{users: users} = Game.get_state(pid)

    assert users == [alice]
  end

  test "start action changes status to turn_pending", %{pid: pid} do
    Game.user_action(pid, %{"action" => "start"})

    TestHelpers.assert_game_status(pid, "turn_pending")
  end

  test "start_turn action changes state to turn_ongoing", %{pid: pid} do
    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => "test"})

    TestHelpers.assert_game_status(pid, "turn_ongoing")
  end

  test "update_shapes action updates shapes", %{pid: pid} do
    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => "test"})
    Game.user_action(pid, %{"action" => "update_shapes", "shapes" => [1, 2]})

    assert %{shapes: [1, 2]} = Game.get_state(pid)

    Game.user_action(pid, %{"action" => "update_shapes", "shapes" => [3, 4]})

    assert %{shapes: [3, 4, 1, 2]} = Game.get_state(pid)
  end

  test "guess action updates user.guessed when correct", %{pid: pid} do
    first_user = %{
      name: "Bob",
      id: "123"
    }

    second_user = %{
      name: "Alice",
      id: "456"
    }

    secret_word = "banana"

    Game.join(pid, first_user)
    Game.join(pid, second_user)
    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => secret_word})

    Game.user_action(pid, %{
      "action" => "guess",
      "value" => secret_word,
      "user" => %{"id" => second_user.id}
    })

    TestHelpers.assert_user_guessed(pid, second_user, true)
  end

  test "guess action does not update user.guessed when incorrect", %{pid: pid} do
    first_user = %{
      name: "Bob",
      id: "123"
    }

    second_user = %{
      name: "Alice",
      id: "456"
    }

    secret_word = "banana"

    Game.join(pid, first_user)
    Game.join(pid, second_user)
    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => secret_word})

    Game.user_action(pid, %{
      "action" => "guess",
      "value" => "WRONG",
      "user" => %{"id" => second_user.id}
    })

    TestHelpers.assert_user_guessed(pid, second_user, false)
  end
end
