defmodule Chatourius.RoomChannel do
  use Phoenix.Channel
  alias Chatourius.Presence
  alias Chatourius.Repo
  alias Chatourius.User
  alias Chatourius.RoomsMap

  def join("room:" <> room_id, _payload, socket) do
    RoomsMap.increment(room_id)
    socket = assign(socket, :room_id, room_id)
    send(self(), :after_join)
    {:ok, socket}
  end

  def terminate(_msg, socket) do
    RoomsMap.decrement(socket.assigns[:room_id])
  end

  def handle_info(:after_join, socket) do
    user = Repo.get(User, socket.assigns.user_id)

    {:ok, _} = Presence.track(socket, user.name, %{
      online_at: inspect(System.system_time(:seconds))
      })
    push socket, "presence_state", Presence.list(socket)
    {:noreply, socket}
  end


  def handle_in("message:new", payload, socket) do
    user = Repo.get(User, socket.assigns.user_id)

    broadcast! socket, "message:new", %{user: user.name, message: payload["message"]}
    {:noreply, socket}
  end
end
