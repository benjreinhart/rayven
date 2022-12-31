defmodule RayvenWeb.LinkLiveTest do
  use RayvenWeb.ConnCase

  import Phoenix.LiveViewTest
  import Rayven.ShareLinksFixtures

  @create_attrs %{aes_iv: "some aes_iv", ciphertext: "some ciphertext", expires_at: "2022-12-27T18:13:00", max_views: 42, passphrase_digest: "some passphrase_digest", passphrase_salt: "some passphrase_salt", views: 42}
  @update_attrs %{aes_iv: "some updated aes_iv", ciphertext: "some updated ciphertext", expires_at: "2022-12-28T18:13:00", max_views: 43, passphrase_digest: "some updated passphrase_digest", passphrase_salt: "some updated passphrase_salt", views: 43}
  @invalid_attrs %{aes_iv: nil, ciphertext: nil, expires_at: nil, max_views: nil, passphrase_digest: nil, passphrase_salt: nil, views: nil}

  defp create_link(_) do
    link = link_fixture()
    %{link: link}
  end

  describe "Index" do
    setup [:create_link]

    test "lists all links", %{conn: conn, link: link} do
      {:ok, _index_live, html} = live(conn, ~p"/links")

      assert html =~ "Listing Links"
      assert html =~ link.aes_iv
    end

    test "saves new link", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/links")

      assert index_live |> element("a", "New Link") |> render_click() =~
               "New Link"

      assert_patch(index_live, ~p"/links/new")

      assert index_live
             |> form("#link-form", link: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#link-form", link: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/links")

      assert html =~ "Link created successfully"
      assert html =~ "some aes_iv"
    end

    test "updates link in listing", %{conn: conn, link: link} do
      {:ok, index_live, _html} = live(conn, ~p"/links")

      assert index_live |> element("#links-#{link.id} a", "Edit") |> render_click() =~
               "Edit Link"

      assert_patch(index_live, ~p"/links/#{link}/edit")

      assert index_live
             |> form("#link-form", link: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#link-form", link: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/links")

      assert html =~ "Link updated successfully"
      assert html =~ "some updated aes_iv"
    end

    test "deletes link in listing", %{conn: conn, link: link} do
      {:ok, index_live, _html} = live(conn, ~p"/links")

      assert index_live |> element("#links-#{link.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#link-#{link.id}")
    end
  end

  describe "Show" do
    setup [:create_link]

    test "displays link", %{conn: conn, link: link} do
      {:ok, _show_live, html} = live(conn, ~p"/links/#{link}")

      assert html =~ "Show Link"
      assert html =~ link.aes_iv
    end

    test "updates link within modal", %{conn: conn, link: link} do
      {:ok, show_live, _html} = live(conn, ~p"/links/#{link}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Link"

      assert_patch(show_live, ~p"/links/#{link}/show/edit")

      assert show_live
             |> form("#link-form", link: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#link-form", link: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/links/#{link}")

      assert html =~ "Link updated successfully"
      assert html =~ "some updated aes_iv"
    end
  end
end
