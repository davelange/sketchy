defmodule Sketchy.Game.Timer do
  alias Sketchy.GameRegistry

  def schedule_turn_end(state) do
    case GameRegistry.get_pid(state.id) do
      {:ok, pid} ->
        Map.put(
          state,
          :timer,
          Process.send_after(
            pid,
            :turn_time_ended,
            state.turn_duration
          )
        )

      _ ->
        state
    end
  end

  def schedule_next_turn(state) do
    case GameRegistry.get_pid(state.id) do
      {:ok, pid} ->
        Map.put(
          state,
          :timer,
          Process.send_after(
            pid,
            :inter_turn_time_ended,
            state.inter_turn_duration
          )
        )

      _ ->
        state
    end
  end

  def cancel(state) when is_reference(state.timer) do
    Process.cancel_timer(state.timer)
    state
  end

  def cancel(state), do: state
end
