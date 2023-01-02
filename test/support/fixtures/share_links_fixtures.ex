defmodule Rayven.ShareLinksFixtures do
  def link_crypto_attributes() do
    %{
      id: rand_bytes(32, :base58),
      aes_iv: rand_bytes(12, :base64),
      passphrase_salt: rand_bytes(64, :base64),
      passphrase_digest: rand_bytes(32, :base16),
      ciphertext: rand_bytes(64, :base64)
    }
  end

  def link_attributes() do
    Map.merge(link_crypto_attributes(), %{max_views: 1, expires_at: expires(1)})
  end

  def link_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(link_attributes())
    |> Rayven.ShareLinks.create_link!()
  end

  def expires(days_from_now) do
    NaiveDateTime.utc_now() |> NaiveDateTime.add(days_from_now, :day)
  end

  def rand_bytes(byte_size, :base16) do
    byte_size
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  def rand_bytes(byte_size, :base58) do
    byte_size
    |> :crypto.strong_rand_bytes()
    |> Base58.encode()
  end

  def rand_bytes(byte_size, :base64) do
    byte_size
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end
end
