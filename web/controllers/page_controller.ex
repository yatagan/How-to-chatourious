defmodule Chatourius.PageController do
  use Chatourius.Web, :controller

  def rooms_list(conn, _params) do
    rooms = Chatourius.RoomsMap.rooms_list()
    render conn, "rooms_list.html", rooms: rooms
  end

  def room(conn, %{"room" => room_id}) do
    conn
    |> assign(:room_id, room_id)
    |> render("room.html")
  end
end
