defmodule Sketchy.Game.Broadcast do
  alias SketchyWeb.Endpoint

  def call(topic, event, payload, return) do
    Endpoint.broadcast(topic, event, payload)
    return
  end
end
