defmodule Chatourius.RoomChannel do
  use Phoenix.Channel
  alias Chatourius.Presence
  alias Chatourius.Repo
  alias Chatourius.User
  alias Chatourius.RoomsMap
  alias Chatourius.Message

  def join("room:" <> room_id, _payload, socket) do
    RoomsMap.increment(room_id)
    socket = assign(socket, :room_id, room_id)
    send(self(), :after_join)
    {:ok, socket}
  end

  def terminate(_msg, socket) do
    user = Repo.get(User, socket.assigns.user_id)
    broadcast! socket, "user:left", %{name: user.name}
    RoomsMap.decrement(socket.assigns[:room_id])
  end

  def handle_info(:after_join, socket) do
    user = Repo.get(User, socket.assigns.user_id)

    {:ok, _} = Presence.track(socket, user.name, %{
      online_at: inspect(System.system_time(:seconds))
      })
    push socket, "presence_state", Presence.list(socket)

    last_messages = Message.fetch_last_messages(socket.assigns.room_id)
    push socket, "last_messages", %{last_messages: last_messages}

    broadcast! socket, "user:joined", %{name: user.name}

    {:noreply, socket}
  end


  def handle_in("message:new", payload, socket) do
    user_id = socket.assigns.user_id
    room_id = socket.assigns.room_id
    message = payload["message"]

    {:ok, stored_message} =
      Message.store_message(%{user_id: user_id, room_id: room_id, text: message})

    user = Repo.get(User, user_id)

    broadcast! socket, "message:new", %{inserted_at: stored_message.inserted_at,
                                        user: user.name, message: payload["message"]}
    {:noreply, socket}
  end
end
