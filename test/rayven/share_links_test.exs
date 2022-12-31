defmodule Rayven.ShareLinksTest do
  use Rayven.DataCase

  alias Rayven.ShareLinks

  describe "links" do
    alias Rayven.ShareLinks.Link

    import Rayven.ShareLinksFixtures

    @invalid_attrs %{aes_iv: nil, ciphertext: nil, expires_at: nil, max_views: nil, passphrase_digest: nil, passphrase_salt: nil, views: nil}

    test "list_links/0 returns all links" do
      link = link_fixture()
      assert ShareLinks.list_links() == [link]
    end

    test "get_link!/1 returns the link with given id" do
      link = link_fixture()
      assert ShareLinks.get_link!(link.id) == link
    end

    test "create_link/1 with valid data creates a link" do
      valid_attrs = %{aes_iv: "some aes_iv", ciphertext: "some ciphertext", expires_at: ~N[2022-12-27 18:13:00], max_views: 42, passphrase_digest: "some passphrase_digest", passphrase_salt: "some passphrase_salt", views: 42}

      assert {:ok, %Link{} = link} = ShareLinks.create_link(valid_attrs)
      assert link.aes_iv == "some aes_iv"
      assert link.ciphertext == "some ciphertext"
      assert link.expires_at == ~N[2022-12-27 18:13:00]
      assert link.max_views == 42
      assert link.passphrase_digest == "some passphrase_digest"
      assert link.passphrase_salt == "some passphrase_salt"
      assert link.views == 42
    end

    test "create_link/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ShareLinks.create_link(@invalid_attrs)
    end

    test "update_link/2 with valid data updates the link" do
      link = link_fixture()
      update_attrs = %{aes_iv: "some updated aes_iv", ciphertext: "some updated ciphertext", expires_at: ~N[2022-12-28 18:13:00], max_views: 43, passphrase_digest: "some updated passphrase_digest", passphrase_salt: "some updated passphrase_salt", views: 43}

      assert {:ok, %Link{} = link} = ShareLinks.update_link(link, update_attrs)
      assert link.aes_iv == "some updated aes_iv"
      assert link.ciphertext == "some updated ciphertext"
      assert link.expires_at == ~N[2022-12-28 18:13:00]
      assert link.max_views == 43
      assert link.passphrase_digest == "some updated passphrase_digest"
      assert link.passphrase_salt == "some updated passphrase_salt"
      assert link.views == 43
    end

    test "update_link/2 with invalid data returns error changeset" do
      link = link_fixture()
      assert {:error, %Ecto.Changeset{}} = ShareLinks.update_link(link, @invalid_attrs)
      assert link == ShareLinks.get_link!(link.id)
    end

    test "delete_link/1 deletes the link" do
      link = link_fixture()
      assert {:ok, %Link{}} = ShareLinks.delete_link(link)
      assert_raise Ecto.NoResultsError, fn -> ShareLinks.get_link!(link.id) end
    end

    test "change_link/1 returns a link changeset" do
      link = link_fixture()
      assert %Ecto.Changeset{} = ShareLinks.change_link(link)
    end
  end
end
