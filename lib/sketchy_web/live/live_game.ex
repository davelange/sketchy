defmodule SketchyWeb.LiveGame do
  use SketchyWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="Game" props={%{id: @id}} socket={@socket} ssr={false} />
    """
  end

  def mount(params, _session, socket) do
    {:ok, assign(socket, :id, params["id"])}
  end
end
