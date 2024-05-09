defmodule Sketchy.Game.ServerTest do
  use ExUnit.Case, async: true

  alias Sketchy.Game.Users
  alias Sketchy.TestHelpers
  alias Sketchy.Game.Server, as: Game

  setup do
    pid =
      start_supervised!(%{
        id: {Game, []},
        start: {Game, :start_link, [%{id: "123", inter_turn_duration: 1}]},
        restart: :transient
      })

    %{pid: pid}
  end

  test "game is created with initial state", %{pid: pid} do
    state = Game.get_state(pid)

    assert %{
             id: "123",
             status: "pending",
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

  test "if user leaves and only 1 user left, game ends", %{pid: pid} do
    bob = Users.create("bob")
    alice = Users.create("alice")

    Game.join(pid, bob)
    Game.join(pid, alice)
    Game.leave(pid, bob.id)

    %{status: status} = Game.get_state(pid)

    assert status == "over"
  end

  test "if active user leaves, turn ends", %{pid: pid} do
    bob = Users.create("bob")
    alice = Users.create("alice")
    jim = Users.create("jim")

    Game.join(pid, bob)
    Game.join(pid, alice)
    Game.join(pid, jim)

    Game.user_action(pid, %{"action" => "start"})

    Game.leave(pid, bob.id)

    state = Game.get_state(pid)

    assert state.status == "turn_over"
  end

  test "start action changes status to turn_pending when more than one user joined", %{pid: pid} do
    Game.join(pid, Users.create("bob"))
    Game.join(pid, Users.create("alice"))
    Game.user_action(pid, %{"action" => "start"})

    TestHelpers.assert_game_status(pid, "turn_pending")
  end

  test "start action fails when only 1 user joined", %{pid: pid} do
    Game.join(pid, Users.create("bob"))
    Game.user_action(pid, %{"action" => "start"})

    TestHelpers.assert_game_status(pid, "pending")
  end

  test "start_turn action changes state to turn_ongoing and changes active user", %{pid: pid} do
    bob = Users.create("bob")

    Game.join(pid, bob)
    Game.join(pid, Users.create("alice"))

    assert %{active_user_id: nil} = Game.get_state(pid)

    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => "test"})

    state = Game.get_state(pid)

    assert state.status == "turn_ongoing"
    assert state.active_user_id == bob.id
  end

  test "update_shapes action updates shapes", %{pid: pid} do
    Game.join(pid, Users.create("bob"))
    Game.join(pid, Users.create("alice"))
    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => "test"})
    Game.user_action(pid, %{"action" => "update_shapes", "shapes" => [1, 2]})

    assert %{shapes: [1, 2]} = Game.get_state(pid)

    Game.user_action(pid, %{"action" => "update_shapes", "shapes" => [3, 4]})

    assert %{shapes: [3, 4, 1, 2]} = Game.get_state(pid)
  end

  test "guess action updates user.guessed when correct", %{pid: pid} do
    bob = Users.create("bob")
    alice = Users.create("alice")

    secret_word = "banana"

    Game.join(pid, bob)
    Game.join(pid, alice)
    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => secret_word})

    Game.user_action(pid, %{
      "action" => "guess",
      "value" => "WRONG",
      "user" => %{"id" => alice.id}
    })

    TestHelpers.assert_user_guessed(pid, alice, false)

    Game.user_action(pid, %{
      "action" => "guess",
      "value" => secret_word,
      "user" => %{"id" => alice.id}
    })

    TestHelpers.assert_user_guessed(pid, alice, true)
  end

  test "if all non active users guess correctly, turn ends", %{pid: pid} do
    bob = Users.create("bob")
    alice = Users.create("alice")
    jim = Users.create("jim")

    secret_word = "banana"

    Game.join(pid, bob)
    Game.join(pid, alice)
    Game.join(pid, jim)

    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => secret_word})

    Game.user_action(pid, %{
      "action" => "guess",
      "value" => secret_word,
      "user" => %{"id" => alice.id}
    })

    TestHelpers.assert_game_status(pid, "turn_ongoing")

    Game.user_action(pid, %{
      "action" => "guess",
      "value" => secret_word,
      "user" => %{"id" => jim.id}
    })

    TestHelpers.assert_game_status(pid, "turn_over")
  end

  test "if user leaves and all others have guessed, turn ends", %{pid: pid} do
    bob = Users.create("bob")
    alice = Users.create("alice")
    jim = Users.create("jim")

    secret_word = "banana"

    Game.join(pid, bob)
    Game.join(pid, alice)
    Game.join(pid, jim)

    Game.user_action(pid, %{"action" => "start"})
    Game.user_action(pid, %{"action" => "start_turn", "value" => secret_word})

    Game.user_action(pid, %{
      "action" => "guess",
      "value" => secret_word,
      "user" => %{"id" => alice.id}
    })

    Game.leave(pid, jim.id)

    TestHelpers.assert_game_status(pid, "turn_over")
  end

  test "when turn ends and all users have played, round advances", %{pid: pid} do
    bob = Users.create("bob")
    alice = Users.create("alice")

    secret_word = "banana"

    Game.join(pid, bob)
    Game.join(pid, alice)

    Game.user_action(pid, %{"action" => "start"})

    Game.user_action(pid, %{"action" => "start_turn", "value" => secret_word})

    Game.user_action(pid, %{
      "action" => "guess",
      "value" => secret_word,
      "user" => %{"id" => alice.id}
    })

    Process.sleep(20)

    assert %{round: 1} = Game.get_state(pid)

    Game.user_action(pid, %{"action" => "start_turn", "value" => secret_word})

    Game.user_action(pid, %{
      "action" => "guess",
      "value" => secret_word,
      "user" => %{"id" => bob.id}
    })

    Process.sleep(20)

    assert %{round: 2} = Game.get_state(pid)
  end
end
