defmodule Rayven.ShareLinksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rayven.ShareLinks` context.
  """

  @doc """
  Generate a link.
  """
  def link_fixture(attrs \\ %{}) do
    {:ok, link} =
      attrs
      |> Enum.into(%{
        aes_iv: "some aes_iv",
        ciphertext: "some ciphertext",
        expires_at: ~N[2022-12-27 18:13:00],
        max_views: 42,
        passphrase_digest: "some passphrase_digest",
        passphrase_salt: "some passphrase_salt",
        views: 42
      })
      |> Rayven.ShareLinks.create_link()

    link
  end
end
