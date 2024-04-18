defmodule Sketchy.Game.Broadcaster do
  def call(to, event, payload) do
    SketchyWeb.Endpoint.broadcast(to, event, payload)
  end
end
