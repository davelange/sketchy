defmodule Sketchy.Game.Points do
  def assign(state, %{"id" => guesser_id}) do
    guesser = Enum.find(state.users, &(&1.id == guesser_id))
    update_points(state, guesser)
  end

  defp update_points(state, %{guessed: false}), do: state

  defp update_points(state, guesser) do
    new_users =
      Enum.map(state.users, fn user ->
        case user.id == guesser.id do
          true -> Map.put(user, :points, get_updated_score(state, user))
          false -> user
        end
      end)

    Map.put(state, :users, new_users)
  end

  defp get_updated_score(state, guesser),
    do: guesser.points + get_placement(state, guesser)

  defp get_placement(state, guesser) do
    previous_correct_guessers =
      state.users |> Enum.filter(&(&1.id != guesser.id && &1.guessed)) |> Enum.count()

    Enum.count(state.users) - previous_correct_guessers
  end
end
