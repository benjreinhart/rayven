defmodule Rayven.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links, primary_key: false) do
      add :id, :string, primary_key: true, null: false

      add :passphrase_salt, :string, null: false
      add :passphrase_digest, :string, null: false
      add :aes_iv, :string, null: false
      add :ciphertext, :binary, null: false

      add :views, :integer,
        default: 0,
        null: false,
        check: %{name: "views_lte_max_views", expr: "views <= max_views"}

      add :max_views, :integer, default: 1, null: false
      add :expires_at, :naive_datetime, null: false

      timestamps()
    end
  end
end
