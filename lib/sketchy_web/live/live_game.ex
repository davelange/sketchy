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
end
