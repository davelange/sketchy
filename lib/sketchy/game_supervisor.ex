defmodule Sketchy.GameSupervisor do
  use DynamicSupervisor

  alias Sketchy.Game.Server

  def start_link(_initial) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: :game_supervisor)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(game_id) do
    spec = %{
      id: {Server, []},
      start: {Server, :start_link, [%{id: game_id}]},
      restart: :transient
    }

    DynamicSupervisor.start_child(:game_supervisor, spec)
  end
end
