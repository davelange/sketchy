defmodule Sketchy.GameSupervisor do
  use DynamicSupervisor

  alias Sketchy.Game

  def start_link(_initial) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: :game_supervisor)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(game_id) do
    params = %{id: game_id}

    DynamicSupervisor.start_child(:game_supervisor, {Game, params})
  end
end
