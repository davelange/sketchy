defmodule Sketchy.Game.Users do
  def create(name),
    do: %{
      name: name,
      id: Ecto.UUID.generate(),
      guessed: false,
      points: 0
    }

  def add(state, user), do: Map.put(state, :users, [user | state.users])

  def remove(state, user_id),
    do: Map.put(state, :users, Enum.filter(state.users, &(&1.id != user_id)))

  def get_next_active(%{active_user: nil} = state) do
    Map.put(state, :active_user, Enum.at(state.users, -1))
  end

  def get_next_active(state) do
    current_idx = Enum.find_index(state.users, &(&1.id == state.active_user.id))
    next_user = Enum.at(state.users, current_idx + 1, Enum.at(state.users, 0))

    Map.put(state, :active_user, next_user)
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
end
