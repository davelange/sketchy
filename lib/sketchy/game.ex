defmodule Sketchy.Game do
  alias Sketchy.GameRegistry
  use GenServer

  def start_link(params) do
    GenServer.start_link(
      __MODULE__,
      %{},
      name: GameRegistry.get_via(params.id)
    )
  end

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end
end
