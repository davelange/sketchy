defmodule SketchyWeb.GameChannelTest do
  use SketchyWeb.ChannelCase

  alias Sketchy.Game.Server

  setup do
    start_supervised!({Server, %{id: "1"}})
    socket = socket(SketchyWeb.UserSocket)

    %{socket: socket}
  end

  test "join fails when game not created", %{socket: socket} do
    assert {:error, "game not found"} =
             subscribe_and_join(socket, SketchyWeb.GameChannel, "game:NOT FOUND")
  end

  test "join succeeds when game created", %{socket: socket} do
    assert {:ok, _state, _socket} = subscribe_and_join(socket, SketchyWeb.GameChannel, "game:1")
  end

  test "ping replies with status ok", %{socket: socket} do
    {:ok, _, chan} = subscribe_and_join(socket, SketchyWeb.GameChannel, "game:1")
    ref = push(chan, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end
end
