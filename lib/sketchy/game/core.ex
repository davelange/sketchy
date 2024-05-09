defmodule Sketchy.Game.Core do
  alias Sketchy.Game.Users
  alias Sketchy.Game.Points
  alias Sketchy.Game.Broadcast
  alias Sketchy.Game.Timer

  # Broadcast

  def broadcast(state, event) do
    Broadcast.call(state.topic, event, get_public_state(state))

    state
  end

  def broadcast(state, event, payload) do
    Broadcast.call(state.topic, event, payload)

    state
  end

  # User entry / exit

  def join(state, user) do
    Users.add(state, user) |> broadcast("user_update")
  end

  def leave(state, user_id) do
    new_state = Users.remove(state, user_id)

    case length(new_state.users) do
      0 ->
        kill_game()

      1 ->
        new_state |> broadcast("user_update") |> end_game()

      _ ->
        new_state |> broadcast("user_update") |> maybe_end_turn()
    end
  end

  # Status updates

  def start_game(%{status: "pending"} = state) when length(state.users) > 1,
    do: state |> get_state_when("turn_pending") |> broadcast("turn_update")

  def start_game(state), do: state

  def start_pending_turn(%{status: "turn_over"} = state),
    do: state |> get_state_when("turn_pending") |> broadcast("turn_update")

  def start_turn(%{status: "turn_pending"} = state, %{"value" => value}),
    do: state |> get_state_when("turn_ongoing", value) |> broadcast("turn_update")

  def end_turn(state), do: state |> get_state_when("turn_over") |> broadcast("turn_update")

  def maybe_end_turn(state) do
    case Users.all_guessed(state) || state.active_user_id == nil do
      true ->
        state |> Timer.cancel() |> end_turn()

      _ ->
        state
    end
  end

  def kill_game, do: Process.send(self(), :stop, [])

  def advance_round(state),
    do: state |> Map.put(:round, state.round + 1) |> Users.reset_played_in_round()

  def maybe_advance_round(state) do
    case Users.all_played_in_round(state) do
      true -> advance_round(state)
      false -> state
    end
  end

  def end_game(state), do: state |> get_state_when("over") |> broadcast("turn_update")

  def maybe_end_game(state) do
    case state.round == state.max_rounds && Users.all_played_in_round(state) do
      true -> end_game(state)
      false -> state
    end
  end

  # User actions

  def update_shapes(%{status: "turn_ongoing"} = state, %{"shapes" => shapes} = payload) do
    new_state = Map.put(state, :shapes, List.flatten([shapes | state.shapes]))

    broadcast(new_state, "shapes_updated", payload)
  end

  def guess(%{status: "turn_ongoing"} = state, %{
        "user" => user,
        "value" => value
      }) do
    correct = guess_is_correct(state, value)

    new_state =
      state |> Users.update_guessed(user, correct) |> Points.assign(user) |> maybe_end_turn()

    broadcast(state, "user_guess", %{
      user: user,
      correct: correct,
      value: value
    })

    if new_state.status == "turn_over" do
      broadcast(new_state, "turn_update")
    end

    new_state
  end

  def guess_is_correct(state, value), do: String.downcase(value) == String.downcase(state.word)

  # State

  def get_initial_state(params),
    do:
      Map.merge(
        %{
          # pending | turn_pending | turn_ongoing | turn_over | over
          status: "pending",
          turn_duration: 60_000,
          inter_turn_duration: 3000,
          word: "",
          id: params.id,
          topic: "game:#{params.id}",
          users: [],
          active_user_id: nil,
          shapes: [],
          timer: nil,
          played_in_round: [],
          round: 1,
          max_rounds: 3
        },
        params
      )

  def get_public_state(state) do
    data = Map.drop(state, [:timer, :word])

    case state.timer do
      nil -> Map.put(data, :remaining_in_turn, state.turn_duration)
      _ -> Map.put(data, :remaining_in_turn, Process.read_timer(state.timer))
    end
  end

  def get_state_when(state, "turn_pending"),
    do:
      state
      |> Map.put(:status, "turn_pending")
      |> Map.put(:shapes, [])
      |> Map.put(:word, "")
      |> maybe_advance_round()
      |> Users.reset_guessed()
      |> Users.advance_active()

  def get_state_when(state, "turn_over"),
    do:
      state
      |> Map.put(:status, "turn_over")
      |> maybe_end_game()
      |> Timer.schedule_next_turn()

  def get_state_when(state, "over"),
    do:
      state
      |> Map.put(:status, "over")

  def get_state_when(state, "turn_ongoing", word),
    do:
      state
      |> Map.put(:status, "turn_ongoing")
      |> Map.put(:word, word)
      |> Timer.schedule_turn_end()
end
