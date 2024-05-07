defmodule Sketchy.Game.PointsTest do
  alias Sketchy.Game.Points
  use ExUnit.Case

  test "doesnt update points if user guessed=false" do
    user_id = "abc"

    state = %{
      users: [
        %{
          id: user_id,
          name: "Bob",
          guessed: false,
          points: 0
        },
        %{
          id: "def",
          name: "Alice",
          guessed: false,
          points: 0
        }
      ]
    }

    updated_state = Points.assign(state, %{"id" => user_id})

    assert state == updated_state
  end

  test "updates points correctly if user guessed=true" do
    user_id = "abc"

    state = %{
      users: [
        %{
          id: user_id,
          name: "Bob",
          guessed: true,
          points: 1
        },
        %{
          id: "def",
          name: "Alice",
          guessed: false,
          points: 0
        }
      ]
    }

    updated_state = Points.assign(state, %{"id" => user_id})
    updated_user = Enum.at(updated_state.users, 0)

    assert updated_user.points == 3
  end
end
