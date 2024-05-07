defmodule Sketchy.Game.Core do
  alias Sketchy.Game.Points
  alias Sketchy.Game.Broadcast
  alias Sketchy.Game.Timer

  def broadcast(state, event) do
    Broadcast.call(state.topic, event, get_public_state(state))

    state
  end

  def broadcast(state, event, payload) do
    Broadcast.call(state.topic, event, payload)

    state
  end

  def join(state, user) do
    broadcast(Map.put(state, :users, [user | state.users]), "user_update")
  end

  def leave(state, user_id) do
    new_users = Enum.filter(state.users, &(&1.id != user_id))

    case new_users do
      [] -> end_game()
      _ -> broadcast(Map.put(state, :users, new_users), "user_update")
    end
  end

  def start_game(%{status: "pending"} = state),
    do: state |> get_state_for("turn_pending") |> broadcast("turn_update")

  def end_game, do: Process.send(self(), :stop, [])

  def start_pending_turn(%{status: "turn_over"} = state),
    do: state |> get_state_for("turn_pending") |> broadcast("turn_update")

  def start_turn(%{status: "turn_pending"} = state, %{"value" => value}),
    do: state |> get_state_for("turn_ongoing", value) |> broadcast("turn_update")

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
      state |> update_user_guessed(user, correct) |> Points.assign(user) |> maybe_end_turn()

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

  def end_turn(state), do: state |> get_state_for("turn_over") |> broadcast("turn_update")

  def maybe_end_turn(state) do
    case Enum.all?(get_non_active_players(state), & &1.guessed) do
      true ->
        Timer.cancel_timer(state.timer)
        end_turn(state)

      _ ->
        state
    end
  end

  def get_initial_state(params),
    do:
      Map.merge(
        %{
          # pending | turn_pending | turn_ongoing | turn_over | over
          status: "pending",
          turn_duration: 60_000,
          word: "",
          id: params.id,
          topic: "game:#{params.id}",
          users: [],
          active_user: nil,
          shapes: [],
          timer: nil
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

  def create_user(name),
    do: %{
      name: name,
      id: Ecto.UUID.generate(),
      guessed: false,
      points: 0
    }

  def get_next_user(%{active_user: nil} = state), do: Enum.at(state.users, -1)

  def get_next_user(state) do
    current_idx = Enum.find_index(state.users, &(&1.id == state.active_user.id))
    Enum.at(state.users, current_idx + 1, Enum.at(state.users, 0))
  end

  def get_non_active_players(state),
    do: Enum.filter(state.users, &(&1.id !== state.active_user.id))

  def update_user_guessed(state, guesser, value) do
    new_users =
      Enum.map(state.users, fn user ->
        case user.id == guesser["id"] do
          true -> Map.put(user, :guessed, value)
          _ -> user
        end
      end)

    Map.put(state, :users, new_users)
  end

  def reset_user_guessed(state), do: Enum.map(state.users, &Map.put(&1, :guessed, false))

  def guess_is_correct(state, value) do
    String.downcase(value) == String.downcase(state.word)
  end

  def get_state_for(state, "turn_pending"),
    do:
      state
      |> Map.put(:status, "turn_pending")
      |> Map.put(:shapes, [])
      |> Map.put(:word, "")
      |> Map.put(:users, reset_user_guessed(state))
      |> Map.put(:active_user, get_next_user(state))

  def get_state_for(state, "turn_over"),
    do: state |> Map.put(:status, "turn_over") |> Map.put(:timer, Timer.schedule_next_turn())

  def get_state_for(state, "turn_ongoing", word),
    do:
      state
      |> Map.put(:status, "turn_ongoing")
      |> Map.put(:word, word)
      |> Map.put(:timer, Timer.schedule_turn_end(state))
end
