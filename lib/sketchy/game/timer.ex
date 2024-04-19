defmodule Sketchy.Game.Timer do
  def schedule_turn_end(state),
    do:
      Process.send_after(
        self(),
        :turn_time_ended,
        state.turn_duration
      )

  def schedule_next_turn(),
    do:
      Process.send_after(
        self(),
        :inter_turn_time_ended,
        5000
      )

  def cancel_timer(ref), do: Process.cancel_timer(ref)
end
