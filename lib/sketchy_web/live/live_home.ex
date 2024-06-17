defmodule SketchyWeb.LiveHome do
  use SketchyWeb, :live_view
  use LiveSvelte.Components

  alias Sketchy.GameSupervisor

  def render(assigns) do
    ~H"""
    <.svelte name="pages/Home" class="h-full bg-blue-300" socket={@socket} />
    """
  end

  def handle_event("create_game", _params, socket) do
    id = Ecto.UUID.generate()

    case GameSupervisor.start_child(id) do
      {:ok, _pid} -> {:noreply, redirect(socket, to: "/game/#{id}")}
      _ -> {:reply, %{message: "something broke"}, socket}
    end
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
