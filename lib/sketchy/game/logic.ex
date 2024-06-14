defmodule Sketchy.Game.Logic do
  alias Sketchy.GameRegistry
  alias Sketchy.Game.Points
  alias Sketchy.Game.Broadcast
  alias Sketchy.Game.Timer
  alias Sketchy.Game.Users

  use Machinery,
    field: :state,
    states: ["pending", "turn_pending", "turn_ongoing", "turn_over", "over"],
    transitions: %{
      "pending" => "turn_pending",
      "turn_pending" => "turn_ongoing",
      "turn_ongoing" => "turn_over",
      "turn_over" => ["over", "turn_pending"],
      "*" => "over"
    }

  # Transition state

  def update_state(struct, next_state, metadata \\ %{}) do
    case Machinery.transition_to(struct, __MODULE__, next_state, metadata) do
      {:ok, result} ->
        result

      {:error, cause} ->
        IO.inspect(cause)
        struct
    end
  end

  # State transitions: before

  def before_transition(struct, "turn_pending", _meta) do
    struct
    |> Map.put(:shapes, [])
    |> Map.put(:word, "")
    |> maybe_advance_round()
    |> Users.reset_guessed()
    |> Users.advance_active()
  end

  def before_transition(struct, "turn_over", _meta) do
    struct
    |> maybe_end_game()
    |> Timer.schedule_next_turn()
  end

  def before_transition(struct, "turn_ongoing", %{"value" => value}) do
    struct
    |> Map.put(:word, value)
    |> Timer.schedule_turn_end()
  end

  def guard_transition(struct, "turn_pending", _meta) do
    if length(struct.users) < 2 do
      {:error, "Cant start turn without more players"}
    end
  end

  # State transitions: after

  def after_transition(struct, _state, _metadata), do: Broadcast.call(struct, "turn_update")

  # User movement

  def add_user(state, user) do
    Users.add(state, user) |> Broadcast.call("user_update")
  end

  def remove_user(state, user_id) do
    new_state = Users.remove(state, user_id)

    case length(new_state.users) do
      0 ->
        kill_game(new_state)

      1 ->
        new_state |> Broadcast.call("user_update") |> end_game()

      _ ->
        new_state |> Broadcast.call("user_update") |> maybe_end_turn()
    end
  end

  # Shapes

  def update_shapes(%{state: "turn_ongoing"} = state, %{"shapes" => shapes} = payload) do
    state
    |> Map.put(:shapes, List.flatten([shapes | state.shapes]))
    |> Broadcast.call("shapes_updated", payload)
  end

  # Guess

  def guess(%{state: "turn_ongoing"} = state, %{
        "user" => user,
        "value" => value
      }) do
    correct = guess_is_correct(state, value)

    state
    |> Users.update_guessed(user, correct)
    |> Points.assign(user)
    |> maybe_end_turn()
    |> Broadcast.call("user_guess", %{
      user: user,
      correct: correct,
      value: value
    })
  end

  defp guess_is_correct(state, value), do: String.downcase(value) == String.downcase(state.word)

  # Logic

  defp advance_round(state),
    do: state |> Map.put(:round, state.round + 1) |> Users.reset_played_in_round()

  defp maybe_advance_round(state) do
    case Users.all_played_in_round(state) do
      true -> advance_round(state)
      false -> state
    end
  end

  defp maybe_end_turn(state) do
    case Users.all_guessed(state) || state.active_user_id == nil do
      true ->
        state |> Timer.cancel() |> update_state("turn_over")

      _ ->
        state
    end
  end

  defp end_game(state), do: update_state(state, "over")

  defp maybe_end_game(state) do
    case state.round == state.max_rounds && Users.all_played_in_round(state) do
      true -> end_game(state)
      false -> state
    end
  end

  defp kill_game(state) do
    {:ok, pid} = GameRegistry.get_pid(state.id)
    Process.send(pid, :stop, [])
  end
end
