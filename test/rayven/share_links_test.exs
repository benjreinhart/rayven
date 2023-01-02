defmodule Rayven.ShareLinksTest do
  use Rayven.DataCase

  alias Rayven.ShareLinks

  describe "links" do
    alias Rayven.ShareLinks.Link

    import Rayven.ShareLinksFixtures

    test "get_link!/1 returns the link with given id" do
      link = link_fixture()
      assert ShareLinks.get_link!(link.id) == link
    end

    test "create_link!/1 with invalid data raises invalid changeset error" do
      assert_raise Ecto.InvalidChangesetError, fn -> ShareLinks.create_link!(%{id: nil}) end

      assert_raise Ecto.InvalidChangesetError, fn -> ShareLinks.create_link!(%{aes_iv: nil}) end

      assert_raise Ecto.InvalidChangesetError, fn ->
        ShareLinks.create_link!(%{passphrase_salt: nil})
      end

      assert_raise Ecto.InvalidChangesetError, fn ->
        ShareLinks.create_link!(%{passphrase_digest: nil})
      end

      assert_raise Ecto.InvalidChangesetError, fn ->
        ShareLinks.create_link!(%{ciphertext: nil})
      end

      assert_raise Ecto.InvalidChangesetError, fn ->
        ShareLinks.create_link!(%{max_views: nil})
      end

      assert_raise Ecto.InvalidChangesetError, fn ->
        ShareLinks.create_link!(%{expires_at: nil})
      end
    end

    test "view_link/2 increments view count if not expired and hasn't reached max_views" do
      link = link_fixture(%{max_views: 2})

      # Link hasn't reached its max views
      assert 0 == link.views

      {:ok, link} = ShareLinks.view_link(link.id, link.passphrase_digest)

      # Link hasn't reached its max views
      assert 1 == link.views

      {:ok, link} = ShareLinks.view_link(link.id, link.passphrase_digest)

      # Link has reached its max views
      assert 2 == link.views

      # Cannot view an expired link
      {:error, nil} = ShareLinks.view_link(link.id, link.passphrase_digest)
    end

    test "view_link/2 does not increment view count if expired" do
      link = link_fixture(%{max_views: 2, expires_at: expires(-1)})

      # Link hasn't reached its max views
      assert 0 == link.views

      # But it is expired
      assert Link.expired?(link)

      # Cannot view an expired link
      {:error, nil} = ShareLinks.view_link(link.id, link.passphrase_digest)
    end

    test "view_link/2 does not increment view count if passphrase_digest doesn't match" do
      invalid_digest = rand_bytes(32, :base16)

      link = link_fixture(%{max_views: 2})

      # Link is viewable
      assert Link.viewable?(link)

      # But it cannot be viewed when the digest doesn't match
      {:error, nil} = ShareLinks.view_link(link.id, invalid_digest)
    end
  end
end
