defmodule Sketchy.Game.Server do
  use GenServer

  alias Sketchy.Game.Core
  alias Sketchy.Game.GameRegistry

  # Client

  def start_link(params) do
    GenServer.start_link(
      __MODULE__,
      Core.get_initial_state(params),
      name: GameRegistry.get_via(params.id)
    )
  end

  def get_state(id), do: GenServer.call(id, :get_state)

  def join(id, user), do: GenServer.cast(id, {:join, user})

  def user_action(id, payload), do: GenServer.cast(id, {:user_action, payload})

  # Callbacks

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, Core.get_public_state(state), state}
  end

  @impl true
  def handle_cast({:join, user}, state) do
    {:noreply, Core.join(state, user)}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "start"}},
        state
      ) do
    {:noreply, Core.start_game(state)}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "start_turn"} = payload},
        state
      ) do
    {:noreply, Core.start_turn(state, payload)}
  end

  def handle_cast(
        {:user_action, %{"action" => "update_shapes"} = payload},
        state
      ) do
    {:noreply, Core.update_shapes(state, payload)}
  end

  @impl true
  def handle_cast(
        {:user_action, %{"action" => "guess"} = payload},
        state
      ) do
    {:noreply, Core.guess(state, payload)}
  end

  @impl true
  def handle_info(:turn_time_ended, state) do
    {:noreply, Core.end_turn(state)}
  end

  @impl true
  def handle_info(:inter_turn_time_ended, state) do
    {:noreply, Core.start_pending_turn(state)}
  end
end
