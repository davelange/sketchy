defmodule Sketchy.Game.Players do
  import Sketchy.Helpers, only: [for_in: 3]

  def create(name),
    do: %{
      name: name,
      id: Ecto.UUID.generate(),
      team: nil,
      played_in_round: false
    }

  def add(state, player) do
    Map.put(state, :players, [player | state.players])
  end

  def remove(state, player_id) do
    Map.put(state, :players, Enum.filter(state.players, &(&1.id != player_id)))
  end

  def choose_team(%{state: "pending"} = state, player_id, team_id) do
    Map.put(
      state,
      :players,
      for_in(state.players, player_id, &Map.put(&1, :team, team_id))
    )
  end

  def choose_team(state, _player_id, _team_id), do: state

  def get_team(state, id) do
    Enum.find(state.players, &(&1.id == id)).team
  end

  def all_played_in_round(state) do
    Enum.all?(state.players, & &1.played_in_round)
  end

  def reset_played_in_round(state) do
    Map.put(state, :players, for_in(state.players, "all", &Map.put(&1, :played_in_round, false)))
  end

  def update_played_in_round(state) do
    actives = Enum.map(state.teams, & &1.active_user_id)

    Map.put(
      state,
      :players,
      for_in(state.players, "all", fn player ->
        case Enum.find(actives, nil, &(&1 == player.id)) do
          nil -> player
          _ -> Map.put(player, :played_in_round, true)
        end
      end)
    )
  end
end
