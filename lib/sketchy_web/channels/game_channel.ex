defmodule SketchyWeb.GameChannel do
  use SketchyWeb, :channel

  alias Sketchy.GameRegistry
  alias Sketchy.Game

  @impl true
  def join("game:" <> game_id, payload, socket) do
    with {:ok, pid} <- get_game_pid(game_id), state <- Game.get_game_state(pid) do
      new_user = %{
        name: payload["user"],
        id: Ecto.UUID.generate()
      }

      Game.join(pid, new_user)
      response = Map.merge(state, %{self: new_user})

      {:ok, response, socket}
    else
      _ -> {:error, "game not found"}
    end
  end

  defp get_game_pid(game_id), do: game_id |> String.replace("game:", "") |> GameRegistry.get_pid()

  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end
end
