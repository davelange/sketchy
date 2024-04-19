defmodule Sketchy.TestHelpers do
  use ExUnit.Case

  alias Sketchy.Game.Server, as: Game

  def assert_game_status(pid, asserted) do
    %{status: status} = Game.get_state(pid)

    assert status == asserted
  end

  def assert_user_guessed(pid, user, has_guessed) do
    %{users: users} = Game.get_state(pid)

    guesser = Enum.find(users, fn u -> u.id == user.id end)

    assert guesser.guessed == has_guessed
  end
end
