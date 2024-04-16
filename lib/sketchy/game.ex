defmodule Sketchy.Game do
  use GenServer

  alias SketchyWeb.Endpoint, as: Endpoint
  alias Sketchy.GameRegistry

  def start_link(params) do
    GenServer.start_link(
      __MODULE__,
      get_initial_state(params.id),
      name: GameRegistry.get_via(params.id)
    )
  end

  def get_game_state(id), do: GenServer.call(id, :get_state)

  def join(id, user), do: GenServer.cast(id, {:join, user})

  defp get_initial_state(id),
    do: %{
      # pending | turn_pending | turn_ongoing | turn_over | over
      status: "pending",
      turn_duration: 60_000,
      word: "",
      id: id,
      topic: "game:#{id}",
      users: [],
      active_user: nil,
      shapes: [],
      timer: nil
    }

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
end
