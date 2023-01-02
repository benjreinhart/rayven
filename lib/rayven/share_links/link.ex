defmodule Rayven.ShareLinks.Link do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string
  @derive {Jason.Encoder, except: [:__meta__, :__struct__]}
  schema "links" do
    field :passphrase_salt, :string
    field :passphrase_digest, :string
    field :aes_iv, :string
    field :ciphertext, :binary

    field :views, :integer
    field :max_views, :integer
    field :expires_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(link, attrs) do
    link
    |> cast(attrs, [
      :id,
      :passphrase_salt,
      :passphrase_digest,
      :aes_iv,
      :ciphertext,
      :max_views,
      :expires_at
    ])
    |> validate_required([
      :id,
      :passphrase_salt,
      :passphrase_digest,
      :aes_iv,
      :ciphertext,
      :max_views,
      :expires_at
    ])
  end

  def viewable?(%__MODULE__{} = link) do
    link.views < link.max_views and not expired?(link)
  end

  def expired?(%__MODULE__{expires_at: expires_at}) do
    now = NaiveDateTime.utc_now()
    :gt == NaiveDateTime.compare(now, expires_at)
  end
end
