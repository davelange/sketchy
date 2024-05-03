defmodule SketchyWeb.LiveGame do
  use SketchyWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="pages/Game" props={%{gameId: @gameId}} socket={@socket} ssr={false} />
    """
  end

  def mount(params, _session, socket) do
    {:ok, assign(socket, :gameId, params["id"])}
  end

  def handle_event("go_to_home", _params, socket) do
    {:noreply, redirect(socket, to: "/")}
  end
end
