defmodule SketchyWeb.LiveGame do
  alias Sketchy.GameRegistry
  use SketchyWeb, :live_view

  def render(assigns) do
    ~H"""
    <.svelte name="pages/Game" props={%{gameId: @gameId}} socket={@socket} ssr={false} />
    """
  end

  def mount(params, _session, socket) do
    case GameRegistry.get_pid(params["id"]) do
      {:ok, _pid} -> {:ok, assign(socket, :gameId, params["id"])}
      {:error, _} -> {:ok, redirect(socket, to: "/")}
    end
  end
end
