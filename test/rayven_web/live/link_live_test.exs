defmodule RayvenWeb.LinkLiveTest do
  use RayvenWeb.ConnCase

  alias Rayven.ShareLinks

  import Phoenix.LiveViewTest
  import Rayven.ShareLinksFixtures

  describe "Index" do
    test "renders homepage", %{conn: conn} do
      {:ok, index_live, html} = live(conn, ~p"/")
      assert html =~ "We keep secrets. You share them."
      assert has_element?(index_live, "#create-form")
      assert has_element?(index_live, "textarea#plaintext")
      assert has_element?(index_live, "select#max-views")
      assert has_element?(index_live, "select#max-days")
      assert has_element?(index_live, "button", "Share secret")
    end

    test "saves new link", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      link_attributes =
        Map.merge(link_crypto_attributes(), %{
          max_views: "1",
          max_days: "1"
        })

      link_id = link_attributes.id

      assert_raise Ecto.NoResultsError, fn -> ShareLinks.get_link!(link_id) end

      html =
        index_live
        |> element("#create-form")
        |> render_hook(:submit, %{link: link_attributes})

      assert_patched(index_live, ~p"/s/#{link_id}/share")
      assert html =~ "Share this link"
      assert has_element?(index_live, "#share-form")

      link = ShareLinks.get_link!(link_id)
      assert 0 == link.views
      assert 1 == link.max_views
    end
  end

  describe "Show" do
    test "displays form to view link", %{conn: conn} do
      link = link_fixture(%{max_views: 2})

      {:ok, show_live, html} = live(conn, ~p"/s/#{link}")

      assert html =~ "Shhh, it&#39;s a secret"
      assert html =~ "Only those with this link can view the contents."
      assert html =~ "Make sure you keep it safe."
      refute has_element?(show_live, "#view-form")

      assert 0 == link.views
      assert 2 == link.max_views

      html =
        show_live
        |> element("#view-button", "View secret")
        |> render_hook(:view, %{passphrase_digest: link.passphrase_digest})

      assert has_element?(
               show_live,
               "#view-form[data-passphrase-salt=\"#{link.passphrase_salt}\"][data-aes-iv=\"#{link.aes_iv}\"][data-ciphertext=\"#{link.ciphertext}\"]"
             )

      # Reload link
      link = ShareLinks.get_link!(link.id)

      # One view was recorded
      assert 1 == link.views
      assert 2 == link.max_views

      # Link still has one view left
      refute html =~ "This link has now expired"

      {:ok, show_live, _html} = live(conn, ~p"/s/#{link}")

      html =
        show_live
        |> element("#view-button", "View secret")
        |> render_hook(:view, %{passphrase_digest: link.passphrase_digest})

      assert has_element?(
               show_live,
               "#view-form[data-passphrase-salt=\"#{link.passphrase_salt}\"][data-aes-iv=\"#{link.aes_iv}\"][data-ciphertext=\"#{link.ciphertext}\"]"
             )

      # Reload link
      link = ShareLinks.get_link!(link.id)

      # One more view was recorded
      assert 2 == link.views
      assert 2 == link.max_views

      # Link is now expired
      assert html =~ "This link has now expired"
    end
  end
end
