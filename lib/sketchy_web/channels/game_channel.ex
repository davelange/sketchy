defmodule SketchyWeb.GameChannel do
  use SketchyWeb, :channel

  alias Sketchy.Game.GameRegistry
  alias Sketchy.Game.Core
  alias Sketchy.Game.Server, as: GameServer

  @impl true
  def join("game:" <> game_id, payload, socket) do
    with {:ok, pid} <- get_game_pid(game_id), state <- GameServer.get_state(pid) do
      new_user = Core.create_user(payload["user"])

      GameServer.join(pid, new_user)

      {:ok, Map.merge(state, %{self: new_user}), socket}
    else
      _ -> {:error, "game not found"}
    end
  end

  defp get_game_pid(game_id), do: game_id |> String.replace("game:", "") |> GameRegistry.get_pid()

  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("user_action", payload, socket) do
    case get_game_pid(socket.topic) do
      {:ok, pid} -> GameServer.user_action(pid, payload)
      _ -> nil
    end

    {:noreply, socket}
  end
end
