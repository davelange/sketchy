defmodule Sketchy.Game.CoreTest do
  use ExUnit.Case

  alias Sketchy.Game.Core

  @game_id "abc"

  setup do
    bob = %{
      name: "Bob",
      id: "abc",
      guessed: false
    }

    alice = %{
      name: "Alice",
      id: "def",
      guessed: false
    }

    %{bob: bob, alice: alice}
  end

  test "get_state_for turn_pending updates state correctly", %{bob: bob, alice: alice} do
    state =
      %{id: @game_id, users: [bob, alice]}
      |> Core.get_initial_state()
      |> Core.get_state_for("turn_pending")

    assert state.status == "turn_pending"
    assert state.shapes == []
    assert state.word == ""
    assert state.active_user == alice
  end

  test "get_state_for turn_over updates state correctly", %{bob: bob, alice: alice} do
    state =
      %{id: @game_id, users: [bob, alice]}
      |> Core.get_initial_state()
      |> Core.get_state_for("turn_over")

    assert state.status == "turn_over"
  end

  test "get_state_for turn_ongoing updates state correctly", %{bob: bob, alice: alice} do
    state =
      %{id: @game_id, users: [bob, alice]}
      |> Core.get_initial_state()
      |> Core.get_state_for("turn_ongoing", "secret word")

    assert state.status == "turn_ongoing"
    assert state.word == "secret word"
  end

  test "guess_is_correct matches strings correctly" do
    state = %{word: "secret"}

    assert Core.guess_is_correct(state, "SEcRet") == true
    assert Core.guess_is_correct(state, "not secret") == false
  end

  test "reset_user_guessed works correctly" do
    users_reset =
      Core.reset_user_guessed(%{
        users: [
          %{
            name: "Bob",
            id: "abc",
            guessed: true
          },
          %{
            name: "Alice",
            id: "def",
            guessed: true
          }
        ]
      })

    assert Enum.find(users_reset, nil, & &1.guessed) == nil
  end

  test "update_user_guessed sets specified user to guessed=true", %{bob: bob, alice: alice} do
    new_state = Core.update_user_guessed(%{users: [bob, alice]}, %{"id" => bob.id}, true)

    assert Enum.at(new_state.users, 0).guessed == true
  end

  test "get_non_active_players returns all users expect active", %{bob: bob, alice: alice} do
    non_active =
      Core.get_non_active_players(%{
        users: [bob, alice],
        active_user: bob
      })

    assert non_active == [alice]
  end

  test "get_next_user gets next user in list if possible", %{bob: bob, alice: alice} do
    initial_state = %{
      users: [bob, alice],
      active_user: bob
    }

    assert Core.get_next_user(initial_state) == alice
  end

  test "get_next_user gets first user in list if needed", %{bob: bob, alice: alice} do
    initial_state = %{
      users: [bob, alice],
      active_user: alice
    }

    assert Core.get_next_user(initial_state) == bob
  end
end
