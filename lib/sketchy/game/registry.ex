defmodule Sketchy.Game.Registry do
  @reg_name :account_process_registry

  def name, do: @reg_name

  def get_pid(id) do
    case Registry.lookup(@reg_name, id) do
      [{pid, _val}] -> {:ok, pid}
      _ -> {:error, "game not found"}
    end
  end

  def get_via(id) do
    {:via, Registry, {@reg_name, id}}
  end
end
