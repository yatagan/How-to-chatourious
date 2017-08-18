defmodule Chatourius.Repo.Migrations.AddMessageType do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :type, :string, default: "message"
    end
  end
end
