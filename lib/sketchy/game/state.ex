defmodule Sketchy.Game.State do
  defstruct state: "pending",
            turn_duration: 60_000,
            inter_turn_duration: 3000,
            word: "",
            id: nil,
            topic: "",
            users: [],
            active_user_id: nil,
            shapes: [],
            timer: nil,
            played_in_round: [],
            round: 1,
            max_rounds: 3

  def init(params) do
    struct(__MODULE__, %{
      id: params.id,
      topic: "game:#{params.id}"
    })
  end

  def get_public(state) do
    data = state |> Map.from_struct() |> Map.drop([:timer, :word])

    case state.timer do
      nil -> Map.put(data, :remaining_in_turn, state.turn_duration)
      _ -> Map.put(data, :remaining_in_turn, Process.read_timer(state.timer))
    end
  end
end
