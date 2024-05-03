defmodule Sketchy.Game.Broadcast do
  alias SketchyWeb.Endpoint

  def call(topic, event, payload) do
    Endpoint.broadcast(topic, event, payload)
  end
end
