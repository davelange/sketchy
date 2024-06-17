defmodule Sketchy.Game.Logic do
  alias Sketchy.Game.Score
  alias Sketchy.Game.Teams
  alias Sketchy.GameRegistry
  alias Sketchy.Game.Broadcast
  alias Sketchy.Game.Timer
  alias Sketchy.Game.Players

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
        IO.inspect("Failed transition: #{cause}")
        struct
    end
  end

  # State transitions: before

  def before_transition(struct, "turn_pending", _meta) do
    struct
    |> Map.put(:shapes, [])
    |> Teams.reset_words()
    |> maybe_advance_round()
    |> Teams.advance_active_players()
    |> Players.update_played_in_round()
  end

  def before_transition(struct, "turn_over", _meta) do
    struct
    |> maybe_end_game()
    |> Timer.schedule_next_turn()
  end

  def before_transition(struct, "turn_ongoing", _meta) do
    Timer.schedule_turn_end(struct)
  end

  # State transitions: guards

  def guard_transition(struct, "turn_pending", _meta) do
    cond do
      Teams.sizes_valid(struct) == false -> {:error, "Teams aren't complete"}
      true -> :ok
    end
  end

  def guard_transition(struct, "turn_ongoing", _meta) do
    cond do
      Teams.all_words_set(struct) == true -> :ok
      true -> {:error, "Teams haven't chosen words yet"}
    end
  end

  # State transitions: after

  def after_transition(struct, _state, _metadata), do: Broadcast.call(struct, "turn_update")

  # User movement

  def add_user(state, user) do
    Players.add(state, user) |> Broadcast.call("user_update")
  end

  def remove_user(state, user_id) do
    new_state = state |> Players.remove(user_id) |> Teams.maybe_unset_active_player(user_id)

    case length(new_state.players) do
      0 ->
        kill_game(new_state)

      1 ->
        new_state |> Broadcast.call("user_update") |> end_game()

      _ ->
        new_state |> Broadcast.call("user_update") |> maybe_end_turn()
    end
  end

  def set_user_team(state, %{"user" => user, "team_id" => team_id}) do
    state |> Players.choose_team(user["id"], team_id) |> Broadcast.call("user_update")
  end

  # Shapes

  def update_shapes(%{state: "turn_ongoing"} = state, %{"shapes" => shapes} = payload) do
    state
    |> Map.put(:shapes, List.flatten([shapes | state.shapes]))
    |> Broadcast.call("shapes_updated", payload)
  end

  def update_shapes(state, _payload), do: state

  # Word

  def set_team_word(state, %{
        "user" => user,
        "value" => value
      }) do
    state
    |> Teams.set_word(Players.get_team(state, user["id"]), value)
    |> maybe_start_turn_ongoing()
  end

  def maybe_start_turn_ongoing(state) do
    cond do
      Teams.all_words_set(state) -> update_state(state, "turn_ongoing")
      true -> state
    end
  end

  def guess(%{state: "turn_ongoing"} = state, %{
        "user" => user,
        "value" => value
      }) do
    team_id = Players.get_team(state, user["id"])
    correct = guess_is_correct(state, value, team_id)

    state
    |> Teams.update_guessed(team_id, correct)
    |> Score.update(team_id, correct)
    |> maybe_end_turn()
    |> Broadcast.call("user_guess", %{
      user: user,
      correct: correct,
      value: value
    })
  end

  defp guess_is_correct(state, value, team_id) do
    word =
      state.teams
      |> Enum.find(&(&1.id == team_id))
      |> Map.fetch!(:word)
      |> String.downcase()

    word == String.downcase(value)
  end

  # Logic

  defp advance_round(state),
    do: state |> Map.put(:round, state.round + 1) |> Players.reset_played_in_round()

  defp maybe_advance_round(state) do
    case Players.all_played_in_round(state) do
      true -> advance_round(state)
      false -> state
    end
  end

  defp maybe_end_turn(state) do
    case Teams.all_words_guessed(state) || Teams.active_player_unset(state) do
      true ->
        state |> Timer.cancel() |> update_state("turn_over")

      _ ->
        state
    end
  end

  defp end_game(state), do: update_state(state, "over")

  defp maybe_end_game(state) do
    case state.round == state.max_rounds && Players.all_played_in_round(state) do
      true -> end_game(state)
      false -> state
    end
  end

  defp kill_game(state) do
    {:ok, pid} = GameRegistry.get_pid(state.id)
    Process.send(pid, :stop, [])
  end
end
