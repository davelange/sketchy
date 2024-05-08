defmodule Sketchy.Game.CoreTest do
  use ExUnit.Case

  alias Sketchy.Game.Core

  @game_id "abc"

  setup do
    bob = %{
      name: "Bob",
      id: "abc",
      guessed: false,
      points: 0
    }

    alice = %{
      name: "Alice",
      id: "def",
      guessed: false,
      points: 0
    }

    %{bob: bob, alice: alice}
  end

  test "get_state_when turn_pending updates state correctly", %{bob: bob, alice: alice} do
    state =
      %{id: @game_id, users: [bob, alice]}
      |> Core.get_initial_state()
      |> Core.get_state_when("turn_pending")

    assert state.status == "turn_pending"
    assert state.shapes == []
    assert state.word == ""
    assert state.active_user == alice
  end

  test "get_state_when turn_over updates state correctly", %{bob: bob, alice: alice} do
    state =
      %{id: @game_id, users: [bob, alice]}
      |> Core.get_initial_state()
      |> Core.get_state_when("turn_over")

    assert state.status == "turn_over"
  end

  test "get_state_when turn_ongoing updates state correctly", %{bob: bob, alice: alice} do
    state =
      %{id: @game_id, users: [bob, alice]}
      |> Core.get_initial_state()
      |> Core.get_state_when("turn_ongoing", "secret word")

    assert state.status == "turn_ongoing"
    assert state.word == "secret word"
  end

  test "guess_is_correct matches strings correctly" do
    state = %{word: "secret"}

    assert Core.guess_is_correct(state, "SEcRet") == true
    assert Core.guess_is_correct(state, "not secret") == false
  end
end
