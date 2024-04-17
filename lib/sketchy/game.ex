defmodule Sketchy.Game do
  use GenServer

  alias SketchyWeb.Endpoint, as: Endpoint
  alias Sketchy.GameRegistry

  @inter_turn_timer_duration 5_000

  # Client

  def start_link(params) do
    GenServer.start_link(
      __MODULE__,
      get_initial_state(params),
      name: GameRegistry.get_via(params.id)
    )
  end

  def get_game_state(id), do: GenServer.call(id, :get_state)

  def join(id, user), do: GenServer.cast(id, {:join, user})

  def user_action(id, payload), do: GenServer.cast(id, {:user_action, payload})

  defp get_next_user(%{active_user: nil} = state), do: Enum.at(state.users, -1)

  defp get_next_user(state) do
    current = Enum.find_index(state.users, &(&1.id == state.active_user.id))
    Enum.at(state.users, current + 1, Enum.at(state.users, 0))
  end

  defp get_non_active_players(state),
    do: Enum.filter(state.users, &(&1.id !== state.active_user.id))

  defp get_public_state(state) do
    data = Map.drop(state, [:timer, :word])

    case state.timer do
      nil -> Map.put(data, :remaining_in_turn, state.turn_duration)
      _ -> Map.put(data, :remaining_in_turn, Process.read_timer(state.timer))
    end
  end

  defp update_user_guessed(state, guesser, value) do
    new_users =
      Enum.map(state.users, fn user ->
        case user.id == guesser["id"] do
          true -> Map.put(user, :guessed, value)
          _ -> user
        end
      end)

    Map.put(state, :users, new_users)
  end

  defp maybe_end_turn(state) do
    case Enum.all?(get_non_active_players(state), & &1.guessed) do
      true ->
        cancel_timer(state.timer)
        end_turn(state)

      _ ->
        state
    end
  end

  defp end_turn(state),
    do: state |> Map.put(:status, "turn_over") |> Map.put(:timer, schedule_next_turn())

  defp start_new_turn(state),
    do:
      state
      |> Map.put(:status, "turn_pending")
      |> Map.put(:shapes, [])
      |> Map.put(:word, "")
      |> Map.put(:active_user, get_next_user(state))

  defp schedule_turn_end(state),
    do:
      Process.send_after(
        self(),
        :turn_time_ended,
        state.turn_duration
      )

  defp schedule_next_turn(),
    do:
      Process.send_after(
        self(),
        :inter_turn_time_ended,
        @inter_turn_timer_duration
      )

  defp cancel_timer(ref), do: Process.cancel_timer(ref)

  defp get_initial_state(params),
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

  # Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:join, user}, state) do
    new_user = Map.put(user, :guessed, false)
    new_state = Map.put(state, :users, [new_user | state.users])
    Endpoint.broadcast(state.topic, "user_joined", new_user)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "start"}},
        %{status: "pending"} = state
      ) do
    new_state = start_new_turn(state)

    Endpoint.broadcast(state.topic, "turn_update", get_public_state(new_state))

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "start_turn", "value" => value}},
        %{status: "turn_pending"} = state
      ) do
    new_state =
      state
      |> Map.put(:status, "turn_ongoing")
      |> Map.put(:word, value)
      |> Map.put(:timer, schedule_turn_end(state))

    Endpoint.broadcast(state.topic, "turn_update", get_public_state(new_state))

    {:noreply, new_state}
  end

  def handle_cast(
        {:user_action, %{"action" => "update_shapes", "shapes" => shapes} = payload},
        %{status: "turn_ongoing"} = state
      ) do
    new_state = Map.put(state, :shapes, List.flatten([shapes | state.shapes]))

    Endpoint.broadcast(state.topic, "shapes_updated", payload)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "guess", "user" => user, "value" => value}},
        %{status: "turn_ongoing"} = state
      ) do
    correct = String.downcase(value) == String.downcase(state.word)

    new_state = state |> update_user_guessed(user, correct) |> maybe_end_turn()

    Endpoint.broadcast(state.topic, "user_guess", %{
      user: user,
      correct: correct,
      value: value
    })

    if new_state.status == "turn_over" do
      Endpoint.broadcast(state.topic, "turn_update", get_public_state(new_state))
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:turn_time_ended, state) do
    new_state = end_turn(state)

    Endpoint.broadcast(state.topic, "turn_update", get_public_state(new_state))

    {:noreply, state}
  end

  @impl true
  def handle_info(:inter_turn_time_ended, state) do
    new_state = start_new_turn(state)

    Endpoint.broadcast(state.topic, "turn_update", get_public_state(new_state))

    {:noreply, new_state}
  end
end
