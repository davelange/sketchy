defmodule Sketchy.Game.UsersTest do
  alias Sketchy.Game.Users
  use ExUnit.Case

  setup do
    user_bob = Users.create("bob")
    user_alice = Users.create("alice")
    user_jim = Users.create("jim")

    %{user_bob: user_bob, user_alice: user_alice, user_jim: user_jim}
  end

  test "creates user with correct initial values" do
    user = Users.create("bob")

    assert user.points == 0
    assert user.guessed == false
  end

  test "add puts user in users list", %{user_bob: user_bob, user_alice: user_alice} do
    state = %{
      users: [user_bob]
    }

    new_state = Users.add(state, user_alice)

    assert Enum.at(new_state.users, 0) == user_alice
  end

  test "remove removes given user from list", %{user_bob: user_bob, user_alice: user_alice} do
    state = %{
      users: [user_bob, user_alice]
    }

    assert Users.remove(state, user_bob.id) == %{users: [user_alice]}
  end

  test "if no active_user, get_next returns last user in list", %{
    user_bob: user_bob,
    user_alice: user_alice
  } do
    state = %{
      users: [user_alice, user_bob],
      active_user: nil
    }

    %{active_user: active_user} = Users.get_next_active(state)

    assert active_user == user_bob
  end

  test "if active_user defined, get_next returns next user in list", %{
    user_bob: user_bob,
    user_alice: user_alice,
    user_jim: user_jim
  } do
    state = %{
      users: [user_alice, user_bob, user_jim],
      active_user: user_bob
    }

    %{active_user: active_user} = Users.get_next_active(state)

    assert active_user == user_jim
  end

  test "update_guessed updates guessed property of given user", %{
    user_bob: user_bob,
    user_alice: user_alice,
    user_jim: user_jim
  } do
    state = %{
      users: [user_alice, user_bob, user_jim]
    }

    %{users: [updated | rest]} = Users.update_guessed(state, %{"id" => user_alice.id}, true)

    assert updated.guessed == true
    assert Enum.all?(rest, &(&1.guessed == false))
  end

  test "reset_guessed sets all guessed properties to false", %{
    user_bob: user_bob,
    user_alice: user_alice,
    user_jim: user_jim
  } do
    users = Enum.map([user_alice, user_bob, user_jim], &Map.put(&1, :guessed, true))
    %{users: reset_users} = Users.reset_guessed(%{users: users})

    assert Enum.all?(reset_users, &(&1.guessed == false))
  end
end
