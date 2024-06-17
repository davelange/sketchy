defmodule Sketchy.Helpers do
  def for_in(list, "all", cb) do
    Enum.map(list, fn item -> cb.(item) end)
  end

  def for_in(list, id, cb) do
    Enum.map(list, fn item ->
      case item.id == id do
        true -> cb.(item)
        false -> item
      end
    end)
  end
end
