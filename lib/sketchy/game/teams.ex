defmodule Sketchy.Game.Teams do
  import Sketchy.Helpers, only: [for_in: 3]

  def create(name) do
    %{
      id: Ecto.UUID.generate(),
      name: name,
      word: nil,
      score: 0,
      word_guessed: false,
      active_user_id: nil
    }
  end

  def sizes_valid(state) do
    state.players
    |> Enum.group_by(& &1.team)
    |> Enum.all?(fn {id, list} -> id !== nil && length(list) > 1 end)
  end

  defp get_next_active(state, team_id) do
    state.players
    |> Enum.filter(&(&1.team == team_id))
    |> Enum.reverse()
    |> Enum.find(%{}, &(&1.played_in_round == false))
    |> Map.get(:id, nil)
  end

  def advance_active_players(state) do
    Map.put(
      state,
      :teams,
      for_in(
        state.teams,
        "all",
        &Map.put(&1, :active_user_id, get_next_active(state, &1.id))
      )
    )
  end

  def reset_words(state) do
    Map.put(
      state,
      :teams,
      for_in(state.teams, "all", &(&1 |> Map.put(:word, nil) |> Map.put(:word_guessed, false)))
    )
  end

  def set_word(state, team_id, word) do
    Map.put(
      state,
      :teams,
      for_in(state.teams, team_id, &Map.put(&1, :word, String.downcase(word)))
    )
  end

  def update_guessed(state, id, correct) do
    Map.put(
      state,
      :teams,
      for_in(state.teams, id, &Map.put(&1, :word_guessed, correct))
    )
  end

  def all_words_set(state) do
    Enum.all?(state.teams, &(&1.word != nil))
  end

  def all_words_guessed(state) do
    Enum.all?(state.teams, & &1.word_guessed)
  end

  def active_player_unset(state) do
    Enum.any?(state.teams, &(&1.active_user_id == nil))
  end

  def maybe_unset_active_player(state, player_id) do
    Map.put(
      state,
      :teams,
      for_in(state.teams, "all", fn team ->
        cond do
          team.active_user_id == player_id -> Map.put(team, :active_user_id, nil)
          true -> team
        end
      end)
    )
  end
end
