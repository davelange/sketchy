defmodule Sketchy.Game.LogicTest do
  alias Sketchy.Game.Logic
  alias Sketchy.Game.State
  alias Sketchy.Game.Users
  alias Sketchy.Game.Server

  use ExUnit.Case

  @game_id "abc"

  setup do
    user_bob = Users.create("bob")
    user_alice = Users.create("alice")

    game =
      %{id: @game_id} |> State.init() |> Logic.add_user(user_alice) |> Logic.add_user(user_bob)

    pid =
      start_supervised!(%{
        id: {Server, []},
        start: {Server, :start_link, [%{id: @game_id, inter_turn_duration: 1}]},
        restart: :transient
      })

    %{bob: user_bob, alice: user_alice, game: game, pid: pid}
  end

  test "update to turn_pending resets state", %{alice: alice, game: game} do
    updated = Logic.update_state(game, "turn_pending")

    assert updated.state == "turn_pending"
    assert updated.shapes == []
    assert updated.word == ""
    assert updated.active_user_id == alice.id
  end

  test "update to turn_pending fails when only 1 player present", %{alice: alice} do
    game =
      %{id: @game_id}
      |> State.init()
      |> Logic.add_user(alice)
      |> Logic.update_state("turn_pending")

    assert game.state == "pending"
  end

  test "game is over when active user leaves and 1 remains", %{alice: alice, game: game} do
    updated = Logic.remove_user(game, alice.id)

    assert updated.state == "over"
  end

  test "game is killed when no users left", %{alice: alice, bob: bob, game: game, pid: pid} do
    game |> Logic.remove_user(alice.id) |> Logic.remove_user(bob.id)

    assert Process.alive?(pid) == false
  end

  test "update to turn_ongoing sets word and schedules turn end", %{game: game} do
    updated =
      game
      |> Logic.update_state("turn_pending")
      |> Logic.update_state("turn_ongoing", %{"value" => "secret"})

    assert updated.word == "secret"
    assert is_reference(updated.timer)
  end

  test "update_shapes adds shapes to list", %{game: game} do
    updated =
      game
      |> Logic.update_state("turn_pending")
      |> Logic.update_state("turn_ongoing", %{"value" => "secret"})
      |> Logic.update_shapes(%{"shapes" => [1, 2]})

    assert %{shapes: [1, 2]} = updated

    updated = Logic.update_shapes(updated, %{"shapes" => [3, 4]})

    assert %{shapes: [3, 4, 1, 2]} = updated
  end

  test "correct guess increases user points and may end turn", %{game: game, bob: bob} do
    word = "secret"
    jim = Users.create("jim")
    initial_bob_points = bob.points

    first_guess =
      game
      |> Logic.add_user(jim)
      |> Logic.update_state("turn_pending")
      |> Logic.update_state("turn_ongoing", %{"value" => word})
      |> Logic.guess(%{"value" => word, "user" => %{"id" => bob.id}})

    new_bob = Enum.find(first_guess.users, &(&1.id === bob.id))

    assert new_bob.points > initial_bob_points
    assert new_bob.guessed == true

    all_guessed = Logic.guess(first_guess, %{"value" => word, "user" => %{"id" => jim.id}})

    assert all_guessed.state === "turn_over"
  end

  test "incorrect guess does nothing", %{game: game, bob: bob} do
    updated =
      game
      |> Logic.update_state("turn_pending")
      |> Logic.update_state("turn_ongoing", %{"value" => "secret"})
      |> Logic.guess(%{"value" => "WRONG", "user" => %{"id" => bob.id}})

    assert Enum.at(updated.users, 0).points == bob.points
    assert updated.state === "turn_ongoing"
  end

  test "if user leaves and all other non actives have guessed, turn ends", %{game: game, bob: bob} do
    word = "secret"
    jim = Users.create("jim")

    updated =
      game
      |> Logic.add_user(jim)
      |> Logic.update_state("turn_pending")
      |> Logic.update_state("turn_ongoing", %{"value" => word})
      |> Logic.guess(%{"value" => word, "user" => %{"id" => bob.id}})

    assert updated.state === "turn_ongoing"

    updated = Logic.remove_user(updated, jim.id)

    assert updated.state === "turn_over"
  end

  test "when new turn starts and all users have played in round, round advances", %{
    game: game,
    bob: bob,
    alice: alice
  } do
    word = "secret"

    first_turn =
      game
      |> Logic.update_state("turn_pending")
      |> Logic.update_state("turn_ongoing", %{"value" => word})
      |> Logic.guess(%{"value" => word, "user" => %{"id" => bob.id}})

    assert first_turn.state == "turn_over"

    second_turn = Logic.update_state(first_turn, "turn_pending")

    assert second_turn.state == "turn_pending"
    assert second_turn.active_user_id == bob.id

    second_turn_end =
      second_turn
      |> Logic.update_state("turn_ongoing", %{"value" => word})
      |> Logic.guess(%{"value" => word, "user" => %{"id" => alice.id}})

    assert second_turn_end.state == "turn_over"

    third_turn = Logic.update_state(second_turn_end, "turn_pending")

    assert third_turn.round == 2
  end
end
