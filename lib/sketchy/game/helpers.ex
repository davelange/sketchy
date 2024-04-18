defmodule Sketchy.Game.Helpers do
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
      guessed: false
    }

  def add_user(state, new_user), do: Map.put(state, :users, [new_user | state.users])

  def get_next_user(%{active_user: nil} = state), do: Enum.at(state.users, -1)

  def get_next_user(state) do
    current = Enum.find_index(state.users, &(&1.id == state.active_user.id))
    Enum.at(state.users, current + 1, Enum.at(state.users, 0))
  end

  def start_new_turn(state),
    do:
      state
      |> Map.put(:status, "turn_pending")
      |> Map.put(:shapes, [])
      |> Map.put(:word, "")
      |> Map.put(:active_user, get_next_user(state))

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

  def maybe_end_turn(state) do
    case Enum.all?(get_non_active_players(state), & &1.guessed) do
      true ->
        # cancel_timer(state.timer)
        end_turn(state)

      _ ->
        state
    end
  end

  def end_turn(state),
    # |> Map.put(:timer, schedule_next_turn())
    do: state |> Map.put(:status, "turn_over")

  def guess_is_correct(state, value) do
    String.downcase(value) == String.downcase(state.word)
  end
end
