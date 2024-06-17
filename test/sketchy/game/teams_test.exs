defmodule Sketchy.Game.TeamsTest do
  alias Sketchy.Game.Players
  alias Sketchy.Game.Teams
  use ExUnit.Case

  setup do
    %{
      bob: Players.create("bob"),
      alice: Players.create("alice"),
      jim: Players.create("jim"),
      jane: Players.create("jane"),
      team1: Teams.create("team1"),
      team2: Teams.create("team2")
    }
  end

  test "creates team with correct initial values", %{team1: team1} do
    assert team1.score == 0
    assert team1.word_guessed == false
    assert team1.active_user_id == nil
    assert team1.name == "team1"
  end

  test "sizes_valid returns true if each team has at least 2 players", %{
    team1: team1,
    team2: team2,
    bob: bob,
    alice: alice,
    jim: jim,
    jane: jane
  } do
    state =
      %{
        teams: [team1, team2],
        players: [bob, alice],
        state: "pending"
      }
      |> Players.choose_team(bob.id, team1.id)
      |> Players.choose_team(alice.id, team2.id)

    assert Teams.sizes_valid(state) == false

    valid_state =
      state
      |> Players.add(jim)
      |> Players.choose_team(jim.id, team1.id)
      |> Players.add(jane)
      |> Players.choose_team(jane.id, team2.id)

    assert Teams.sizes_valid(valid_state) == true
  end

  test "if no active_user in team, advance_active returns last user in list", %{
    team1: team1,
    bob: bob,
    alice: alice
  } do
    state =
      %{
        teams: [team1],
        players: [bob, alice],
        state: "pending"
      }
      |> Players.choose_team(bob.id, team1.id)
      |> Players.choose_team(alice.id, team1.id)

    assert Enum.at(state.teams, 0).active_user_id == nil

    update = Teams.advance_active_players(state)

    assert Enum.at(update.teams, 0).active_user_id == alice.id
  end

  test "if active_user defined, advance_active returns last user in list that has not played", %{
    team1: team1,
    bob: bob,
    alice: alice,
    jane: jane
  } do
    state =
      %{
        teams: [team1],
        players: [bob, alice, jane],
        state: "pending"
      }
      |> Players.choose_team(bob.id, team1.id)
      |> Players.choose_team(alice.id, team1.id)

    state = Teams.advance_active_players(state)
    state = Teams.advance_active_players(state)

    assert Enum.at(state.teams, 0).active_user_id == alice.id
  end

  test "set_word sets word of correct team", %{team1: team1, team2: team2} do
    state = Teams.set_word(%{teams: [team1, team2]}, team1.id, "secret")
    assert Enum.at(state.teams, 0).word == "secret"
    assert Enum.at(state.teams, 1).word == nil
  end

  test "reset_word sets word and word_guessed of all teams to nil", %{team1: team1, team2: team2} do
    state =
      %{teams: [team1, team2]}
      |> Teams.set_word(team1.id, "secret")
      |> Teams.set_word(team1.id, "hello")
      |> Teams.reset_words()

    assert Enum.at(state.teams, 0).word == nil
    assert Enum.at(state.teams, 0).word_guessed == false
    assert Enum.at(state.teams, 1).word == nil
  end

  test "update_guessed sets word_guessed of correct team to given", %{team1: team1, team2: team2} do
    state =
      %{teams: [team1, team2]}
      |> Teams.update_guessed(team1.id, true)
      |> Teams.update_guessed(team2.id, false)

    assert Enum.at(state.teams, 0).word_guessed == true
    assert Enum.at(state.teams, 1).word_guessed == false
  end

  test "maybe_unset_active_player unsets active player if given id matches", %{
    team1: team1,
    team2: team2,
    bob: bob,
    alice: alice
  } do
    state =
      %{teams: [team1, team2], players: [bob, alice], state: "pending"}
      |> Players.choose_team(bob.id, team1.id)
      |> Players.choose_team(alice.id, team1.id)
      |> Teams.advance_active_players()
      |> Teams.maybe_unset_active_player("abc")

    assert Enum.at(state.teams, 0).active_user_id == alice.id

    state = Teams.maybe_unset_active_player(state, alice.id)

    assert Enum.at(state.teams, 0).active_user_id == nil
  end
end
