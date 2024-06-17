defmodule Sketchy.Game.LogicTest do
  alias Sketchy.TestHelpers
  alias Sketchy.Game.Logic
  alias Sketchy.Game.State
  alias Sketchy.Game.Players
  alias Sketchy.Game.Server

  use ExUnit.Case

  @game_id "abc"

  setup do
    pid =
      start_supervised!(%{
        id: {Server, []},
        start: {Server, :start_link, [%{id: @game_id, inter_turn_duration: 1}]},
        restart: :transient
      })

    %{
      bob: Players.create("bob"),
      alice: Players.create("alice"),
      jim: Players.create("jim"),
      jane: Players.create("jane"),
      game: State.init(%{id: @game_id}),
      pid: pid
    }
  end

  test "update to turn_pending fails when teams not complete", %{alice: alice, bob: bob} do
    game = State.init(%{id: @game_id})

    update =
      game
      |> TestHelpers.add_players([alice, bob])
      |> TestHelpers.set_equal_teams()

    assert update.state == "pending"
  end

  test "update to turn_pending resets state when teams complete", %{
    alice: alice,
    bob: bob,
    jim: jim,
    jane: jane,
    game: game
  } do
    game =
      game
      |> TestHelpers.add_players([alice, bob, jane, jim])
      |> TestHelpers.set_equal_teams()
      |> Logic.update_state("turn_pending")

    assert game.state == "turn_pending"
    assert game.shapes == []
  end

  test "game is killed when no users left", %{alice: alice, bob: bob, game: game, pid: pid} do
    game
    |> Logic.add_user(alice)
    |> Logic.add_user(bob)
    |> Logic.remove_user(alice.id)
    |> Logic.remove_user(bob.id)

    assert Process.alive?(pid) == false
  end

  test "when all words set, state updates to turn_ongoing", %{
    game: game,
    alice: alice,
    bob: bob,
    jim: jim,
    jane: jane
  } do
    game =
      game
      |> TestHelpers.add_players([alice, bob, jane, jim])
      |> TestHelpers.set_equal_teams()
      |> Logic.update_state("turn_pending")
      |> Logic.set_team_word(%{
        "user" => %{"id" => bob.id},
        "value" => "banana"
      })
      |> Logic.set_team_word(%{
        "user" => %{"id" => alice.id},
        "value" => "apple"
      })

    assert game.state == "turn_ongoing"
    assert is_reference(game.timer)
    assert Enum.at(game.teams, 0).word == "banana"
    assert Enum.at(game.teams, 1).word == "apple"
  end

  test "update_shapes adds shapes to list", %{
    game: game,
    alice: alice,
    bob: bob,
    jim: jim,
    jane: jane
  } do
    updated =
      game
      |> TestHelpers.add_players([alice, bob, jane, jim])
      |> TestHelpers.set_equal_teams()
      |> Logic.update_state("turn_pending")
      |> Logic.set_team_word(%{
        "user" => %{"id" => bob.id},
        "value" => "banana"
      })
      |> Logic.set_team_word(%{
        "user" => %{"id" => alice.id},
        "value" => "apple"
      })
      |> Logic.update_shapes(%{"shapes" => [1, 2]})

    assert %{shapes: [1, 2]} = updated

    updated = Logic.update_shapes(updated, %{"shapes" => [3, 4]})

    assert %{shapes: [3, 4, 1, 2]} = updated
  end

  test "correct guess increases user points and may end turn", %{
    game: game,
    bob: bob,
    alice: alice,
    jim: jim,
    jane: jane
  } do
    word = "secret"

    first_guess =
      game
      |> TestHelpers.add_players([alice, bob, jane, jim])
      |> TestHelpers.set_equal_teams()
      |> Logic.update_state("turn_pending")
      |> Logic.set_team_word(%{
        "user" => %{"id" => bob.id},
        "value" => word
      })
      |> Logic.set_team_word(%{
        "user" => %{"id" => alice.id},
        "value" => word
      })
      |> Logic.guess(%{
        "user" => %{"id" => bob.id},
        "value" => word
      })

    new_team1 = Enum.at(first_guess.teams, 0)

    assert new_team1.score == 3
    assert new_team1.word_guessed == true

    all_guessed = Logic.guess(first_guess, %{"value" => word, "user" => %{"id" => alice.id}})

    new_team2 = Enum.at(all_guessed.teams, 1)

    assert new_team2.word_guessed == true
    assert new_team2.score == 1
    assert all_guessed.state === "turn_over"
  end

  test "incorrect guess does nothing", %{
    game: game,
    bob: bob,
    alice: alice,
    jim: jim,
    jane: jane
  } do
    word = "secret"

    first_guess =
      game
      |> TestHelpers.add_players([alice, bob, jane, jim])
      |> TestHelpers.set_equal_teams()
      |> Logic.update_state("turn_pending")
      |> Logic.set_team_word(%{
        "user" => %{"id" => bob.id},
        "value" => word
      })
      |> Logic.set_team_word(%{
        "user" => %{"id" => alice.id},
        "value" => word
      })
      |> Logic.guess(%{
        "user" => %{"id" => bob.id},
        "value" => "WRONG"
      })

    new_team1 = Enum.at(first_guess.teams, 0)

    assert new_team1.score == 0
    assert new_team1.word_guessed == false
  end

  test "when new turn starts and all users have played in round, round advances", %{
    game: game,
    bob: bob,
    alice: alice,
    jim: jim,
    jane: jane
  } do
    word = "secret"

    update =
      game
      |> TestHelpers.add_players([alice, bob, jim, jane])
      |> TestHelpers.set_equal_teams()
      |> Logic.update_state("turn_pending")
      |> Logic.set_team_word(%{
        "user" => %{"id" => bob.id},
        "value" => word
      })
      |> Logic.set_team_word(%{
        "user" => %{"id" => alice.id},
        "value" => word
      })
      |> Logic.guess(%{"value" => word, "user" => %{"id" => bob.id}})
      |> Logic.guess(%{"value" => word, "user" => %{"id" => alice.id}})
      |> Logic.update_state("turn_pending")
      |> Logic.set_team_word(%{
        "user" => %{"id" => jim.id},
        "value" => word
      })
      |> Logic.set_team_word(%{
        "user" => %{"id" => jane.id},
        "value" => word
      })
      |> Logic.guess(%{"value" => word, "user" => %{"id" => bob.id}})
      |> Logic.guess(%{"value" => word, "user" => %{"id" => alice.id}})

    assert update.state == "turn_over"

    update = Logic.update_state(update, "turn_pending")

    assert update.state == "turn_pending"

    assert update.round == 2
  end
end
