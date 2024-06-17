defmodule Sketchy.Game.State do
  alias Sketchy.Game.Teams

  defstruct state: "pending",
            turn_duration: 60_000,
            inter_turn_duration: 3000,
            id: nil,
            topic: "",
            players: [],
            teams: [],
            shapes: [],
            timer: nil,
            round: 1,
            max_rounds: 3

  def init(params) do
    struct(
      __MODULE__,
      Map.merge(params, %{
        id: params.id,
        topic: "game:#{params.id}",
        teams: [
          Teams.create("Team 1"),
          Teams.create("Team 2")
        ]
      })
    )
  end

  def get_public(state) do
    data = state |> Map.from_struct() |> Map.drop([:timer, :word])

    case state.timer do
      nil -> Map.put(data, :remaining_in_turn, state.turn_duration)
      _ -> Map.put(data, :remaining_in_turn, Process.read_timer(state.timer))
    end
  end
end
