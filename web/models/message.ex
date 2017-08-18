defmodule Chatourius.Message do
  use Chatourius.Web, :model
  import Ecto.Query
  import Ecto.DateTime
  alias Chatourius.Repo

  schema "messages" do
    field :text, :string
    field :room_id, :string
    field :type, :string # "message" or "event"
    belongs_to :user, Chatourius.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:text, :room_id, :user_id, :type])
    |> validate_required([:text, :room_id, :user_id, :type])
  end

  def store_message(params) do
    Repo.insert changeset(%Chatourius.Message{}, params)
  end

  def fetch_last_messages(room_id) do
    query = from m in Chatourius.Message,
              join: u in Chatourius.User,
              where: m.user_id == u.id and m.room_id == ^room_id,
              order_by: [desc: m.inserted_at],
              limit: 100,
              preload: [:user]

    Repo.all(query)
    |> Enum.reverse
    |> Enum.map fn msg ->
        %{inserted_at: Ecto.DateTime.to_iso8601(msg.inserted_at),
          user: msg.user.name,
          text: msg.text,
          type: msg.type} end
  end
end
