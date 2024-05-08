defmodule Sketchy.Game.Timer do
  def schedule_turn_end(state),
    do:
      Map.put(
        state,
        :timer,
        Process.send_after(
          self(),
          :turn_time_ended,
          state.turn_duration
        )
      )

  def schedule_next_turn(%{status: "turn_over"} = state),
    do:
      Map.put(
        state,
        :timer,
        Process.send_after(
          self(),
          :inter_turn_time_ended,
          5000
        )
      )

  def schedule_next_turn(state), do: state

  def cancel_timer(ref), do: Process.cancel_timer(ref)
end
