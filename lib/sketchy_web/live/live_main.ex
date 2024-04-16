defmodule SketchyWeb.LiveMain do
  use SketchyWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="Main" props={%{number: @number}} socket={@socket} ssr={false} />
    """
  end

  def handle_event("set_number", %{"number" => number}, socket) do
    {:noreply, assign(socket, :number, number)}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :number, 5)}
  end
end
