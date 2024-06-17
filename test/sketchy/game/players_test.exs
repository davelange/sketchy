defmodule Sketchy.Game.PlayersTest do
  use ExUnit.Case

  alias Sketchy.Game.Players

  setup do
    user_bob = Players.create("bob")
    user_alice = Players.create("alice")
    user_jim = Players.create("jim")

    %{user_bob: user_bob, user_alice: user_alice, user_jim: user_jim}
  end

  test "creates user with correct initial values" do
    user = Players.create("bob")

    assert user.played_in_round == false
    assert user.name == "bob"
  end

  test "add puts user in users list", %{user_bob: user_bob, user_alice: user_alice} do
    state = %{
      players: [user_bob]
    }

    new_state = Players.add(state, user_alice)

    assert Enum.at(new_state.players, 0) == user_alice
  end

  test "remove removes given user from list", %{user_bob: user_bob, user_alice: user_alice} do
    state = %{
      players: [user_bob, user_alice]
    }

    assert %{players: [user_alice]} == Players.remove(state, user_bob.id)
  end

  test "choose_team updates the team_id of correct user", %{
    user_bob: user_bob,
    user_alice: user_alice
  } do
    state = %{players: [user_bob, user_alice], state: "pending"}

    update = Players.choose_team(state, user_bob.id, "team1")

    assert Enum.at(update.players, 0).team == "team1"
    assert Enum.at(update.players, 1).team == nil
  end

  test "choose_team does nothing if state not pending", %{
    user_bob: user_bob,
    user_alice: user_alice
  } do
    state = %{players: [user_bob, user_alice], state: "turn_pending"}

    update = Players.choose_team(state, user_bob.id, "team1")

    assert Enum.at(update.players, 0).team == nil
    assert Enum.at(update.players, 1).team == nil
  end

  test "update_played_in_round updates played_in_round of active players", %{
    user_bob: user_bob,
    user_alice: user_alice
  } do
    state = %{players: [user_bob, user_alice], teams: [%{active_user_id: user_bob.id}]}

    update = Players.update_played_in_round(state)

    assert Enum.at(update.players, 0).played_in_round == true
    assert Enum.at(update.players, 1).played_in_round == false
  end

  test "reset_played_in_round sets all guessed properties to false", %{
    user_bob: user_bob,
    user_alice: user_alice,
    user_jim: user_jim
  } do
    users = Enum.map([user_alice, user_bob, user_jim], &Map.put(&1, :played_in_round, true))
    %{players: reset_users} = Players.reset_played_in_round(%{players: users})

    assert Enum.all?(reset_users, &(&1.played_in_round == false))
  end
end
