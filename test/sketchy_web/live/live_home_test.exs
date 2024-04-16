defmodule SketchyWeb.LiveHomeTest do
  use SketchyWeb.ConnCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  test "renders initial view", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Create game"

    assert {:ok, _view, _html} = live(conn)
  end

  test "redirects to game url on create_game", %{conn: conn} do
    conn = get(conn, "/")
    {:ok, view, _html} = live(conn)

    {_res, {:redirect, %{to: url}}} = render_hook(view, "create_game")

    assert_redirected(view, url)
  end
end
