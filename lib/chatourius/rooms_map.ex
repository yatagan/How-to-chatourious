defmodule Chatourius.RoomsMap do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def increment(room_id) do
    Agent.update(__MODULE__, fn map ->
      count = Map.get(map, room_id, 0)
      Map.put(map, room_id, count + 1)
    end)
  end

  def decrement(room_id) do
    Agent.update(__MODULE__, fn map ->
      {:ok, count} = Map.fetch(map, room_id)
      if count == 1 do
        Map.delete(map, room_id)
      else
        Map.put(map, room_id, count - 1)
      end
    end)
  end

  def rooms_list do
    Agent.get(__MODULE__, fn map -> Map.keys(map) end)
  end
end
