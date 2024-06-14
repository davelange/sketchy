defmodule Sketchy.Game.Broadcast do
  alias Sketchy.Game.State
  alias SketchyWeb.Endpoint

  def call(state, event) do
    Endpoint.broadcast(state.topic, event, State.get_public(state))

    state
  end

  def call(state, event, payload) do
    Endpoint.broadcast(state.topic, event, payload)

    state
  end
end
