defmodule Sketchy.Game.Score do
  alias Sketchy.Helpers

  # 3 points if first to guess
  # 1 point if second to guess
  # 0 points if no guess

  def update(state, team_id, true) do
    Map.put(
      state,
      :teams,
      Helpers.for_in(
        state.teams,
        team_id,
        &Map.put(&1, :score, &1.score + get_score_inc(state, team_id))
      )
    )
  end

  def update(state, _team_id, false), do: state

  def get_score_inc(state, team_id) do
    other_team = Enum.find(state.teams, &(&1.id != team_id))

    case other_team.word_guessed do
      true -> 1
      false -> 3
    end
  end
end
