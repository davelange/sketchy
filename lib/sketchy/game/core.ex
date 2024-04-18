defmodule Sketchy.Game.Core do
  alias Sketchy.Game.Broadcaster
  alias Sketchy.Game.Helpers

  def join(state, user) do
    Broadcaster.call(state.topic, "user_joined", user)

    Helpers.add_user(state, user)
  end

  def start_game(%{status: "pending"} = state) do
    new_state = Helpers.start_new_turn(state)

    Broadcaster.call(state.topic, "turn_update", Helpers.get_public_state(new_state))

    new_state
  end

  def start_turn(%{status: "turn_pending"} = state, %{"value" => value}) do
    new_state =
      state
      |> Map.put(:status, "turn_ongoing")
      |> Map.put(:word, value)

    # |> Map.put(:timer, schedule_turn_end(state))

    Broadcaster.call(state.topic, "turn_update", Helpers.get_public_state(new_state))
  end

  def update_shapes(%{status: "turn_ongoing"} = state, %{"shapes" => shapes} = payload) do
    new_state = Map.put(state, :shapes, List.flatten([shapes | state.shapes]))

    Broadcaster.call(state.topic, "shapes_updated", payload)

    new_state
  end

  def guess(%{status: "turn_ongoing"} = state, %{
        "action" => "guess",
        "user" => user,
        "value" => value
      }) do
    correct = Helpers.guess_is_correct(state, value)
    new_state = state |> Helpers.update_user_guessed(user, correct) |> Helpers.maybe_end_turn()

    Broadcaster.call(state.topic, "user_guess", %{
      user: user,
      correct: correct,
      value: value
    })

    if new_state.status == "turn_over" do
      Broadcaster.call(state.topic, "turn_update", Helpers.get_public_state(new_state))
    end

    new_state
  end
end
