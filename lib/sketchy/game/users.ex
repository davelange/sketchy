defmodule Sketchy.Game.Users do
  def create(name),
    do: %{
      name: name,
      id: Ecto.UUID.generate(),
      guessed: false,
      points: 0,
      played_in_round: false
    }

  def add(state, user), do: Map.put(state, :users, [user | state.users])

  def remove(state, user_id),
    do: Map.put(state, :users, Enum.filter(state.users, &(&1.id != user_id)))

  defp get_next_active(%{active_user: nil} = state), do: Enum.at(state.users, -1)

  defp get_next_active(state),
    do: state.users |> Enum.reverse() |> Enum.find(&(&1.played_in_round == false))

  def advance_active(state) do
    next_user = get_next_active(state)

    state
    |> Map.put(:active_user, next_user)
    |> Map.put(:users, update_played_in_round(state, next_user.id))
  end

  defp get_non_active(state), do: Enum.filter(state.users, &(&1.id !== state.active_user.id))

  def update_guessed(state, guesser, correct) do
    new_users =
      Enum.map(state.users, fn user ->
        case user.id == guesser["id"] do
          true -> Map.put(user, :guessed, correct)
          _ -> user
        end
      end)

    Map.put(state, :users, new_users)
  end

  def all_guessed(state), do: Enum.all?(get_non_active(state), & &1.guessed)

  def reset_guessed(state) do
    new_users = Enum.map(state.users, &Map.put(&1, :guessed, false))

    Map.put(state, :users, new_users)
  end

  def all_played_in_round(state), do: Enum.all?(state.users, & &1.played_in_round)

  def reset_played_in_round(state) do
    new_users = Enum.map(state.users, &Map.put(&1, :played_in_round, false))

    Map.put(state, :users, new_users)
  end

  defp update_played_in_round(state, user_id),
    do:
      Enum.map(state.users, fn user ->
        case user.id == user_id do
          true -> Map.put(user, :played_in_round, true)
          _ -> user
        end
      end)
end
