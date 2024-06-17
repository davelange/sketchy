defmodule Sketchy.TestHelpers do
  alias Sketchy.Game.Logic
  use ExUnit.Case

  def add_players(game, users) do
    Enum.reduce(users, game, fn user, acc -> Logic.add_user(acc, user) end)
  end

  def set_equal_teams(game) do
    game.players
    |> Enum.with_index(fn element, index -> {index, element} end)
    |> Enum.reduce(game, fn {idx, user}, acc ->
      case Integer.mod(idx, 2) == 0 do
        true ->
          Logic.set_user_team(acc, %{
            "user" => %{"id" => user.id},
            "team_id" => Enum.at(game.teams, 0).id
          })

        false ->
          Logic.set_user_team(acc, %{
            "user" => %{"id" => user.id},
            "team_id" => Enum.at(game.teams, 1).id
          })
      end
    end)
  end
end
