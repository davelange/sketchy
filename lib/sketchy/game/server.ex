defmodule Sketchy.Game.Server do
  use GenServer

  alias Sketchy.Game.State
  alias Sketchy.Game.Logic
  alias Sketchy.GameRegistry

  # Client

  def start_link(params) do
    GenServer.start_link(
      __MODULE__,
      State.init(params),
      name: GameRegistry.get_via(params.id)
    )
  end

  def get_state(id), do: GenServer.call(id, :get_state)

  def join(id, user), do: GenServer.cast(id, {:join, user})

  def leave(id, user_id), do: GenServer.cast(id, {:leave, user_id})

  def user_action(id, payload), do: GenServer.cast(id, {:user_action, payload})

  # Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, State.get_public(state), state}
  end

  @impl true
  def handle_cast({:join, user}, state) do
    {:noreply, Logic.add_user(state, user)}
  end

  @impl true
  def handle_cast({:leave, user_id}, state) do
    {:noreply, Logic.remove_user(state, user_id)}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "start"}},
        state
      ) do
    {:noreply, Logic.update_state(state, "turn_pending")}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "start_turn"} = payload},
        state
      ) do
    {:noreply, Logic.update_state(state, "turn_ongoing", payload)}
  end

  @impl true
  def handle_cast(
        {:user_action,
         %{
           "action" => "choose_team"
         } = payload},
        state
      ) do
    {:noreply, Logic.set_user_team(state, payload)}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "set_word"} = payload},
        state
      ) do
    {:noreply, Logic.set_team_word(state, payload)}
  end

  def handle_cast(
        {:user_action, %{"action" => "update_shapes"} = payload},
        state
      ) do
    {:noreply, Logic.update_shapes(state, payload)}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "guess"} = payload},
        state
      ) do
    {:noreply, Logic.guess(state, payload)}
  end

  @impl true
  def handle_info(:turn_time_ended, state) do
    {:noreply, Logic.update_state(state, "turn_over")}
  end

  @impl true
  def handle_info(:inter_turn_time_ended, state) do
    {:noreply, Logic.update_state(state, "turn_pending")}
  end

  @impl true
  def handle_info(:stop, state) do
    {:stop, :shutdown, state}
  end
end
