defmodule RayvenWeb.LinkLive.Index do
  use RayvenWeb, :live_view

  alias Rayven.ShareLinks
  alias Rayven.ShareLinks.Link

  # To simplify database query logic, we will handle 'unlimited'
  # max views as a very large number instead, i.e.,  the maximum
  # signed integer that can fit in 8 bytes, or 9,223,372,036,854,775,807.
  @unlimited 2 ** 63 - 1

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :link, nil)
  end

  defp apply_action(%{assigns: %{link: %Link{}}} = socket, :share, _params) do
    socket
  end

  # If there is not already a link in the socket assigns, assign one by loading it from
  # the database. This should only happen when the page is refreshed or landed on directly.
  defp apply_action(socket, :share, %{"id" => id}) do
    assign(socket, :link, ShareLinks.get_link!(id))
  end

  @impl true
  def handle_event("submit", %{"link" => link_params}, socket) do
    id = Map.get(link_params, "id")
    passphrase_salt = Map.get(link_params, "passphrase_salt")
    passphrase_digest = Map.get(link_params, "passphrase_digest")
    aes_iv = Map.get(link_params, "aes_iv")
    ciphertext = Map.get(link_params, "ciphertext")

    max_views =
      link_params
      |> Map.get("max_views", "1")
      |> convert_max_views()

    expires_at =
      link_params
      |> Map.get("max_days", "1")
      |> convert_max_days()

    link =
      ShareLinks.create_link!(%{
        id: id,
        passphrase_salt: passphrase_salt,
        passphrase_digest: passphrase_digest,
        aes_iv: aes_iv,
        ciphertext: ciphertext,
        max_views: max_views,
        expires_at: expires_at
      })

    {:noreply,
     socket
     |> assign(:link, link)
     |> push_patch(to: ~p"/s/#{link}/share")}
  end

  defp convert_max_views("1"), do: 1
  defp convert_max_views("2"), do: 2
  defp convert_max_views("3"), do: 3
  defp convert_max_views("5"), do: 5
  defp convert_max_views("10"), do: 10
  defp convert_max_views("20"), do: 20
  defp convert_max_views("50"), do: 50
  defp convert_max_views("unlimited"), do: @unlimited

  defp convert_max_days("1"), do: days_from_now_as_datetime(1)
  defp convert_max_days("2"), do: days_from_now_as_datetime(2)
  defp convert_max_days("3"), do: days_from_now_as_datetime(3)
  defp convert_max_days("7"), do: days_from_now_as_datetime(7)
  defp convert_max_days("14"), do: days_from_now_as_datetime(14)
  defp convert_max_days("30"), do: days_from_now_as_datetime(30)
  defp convert_max_days("90"), do: days_from_now_as_datetime(90)

  defp days_from_now_as_datetime(days) do
    NaiveDateTime.add(now(), days, :day)
  end

  defp days_from_now(date) do
    NaiveDateTime.diff(date, now(), :day)
  end

  defp now() do
    NaiveDateTime.utc_now()
  end

  defp expiration_message(%Link{max_views: nil, expires_at: expires_at}) do
    days = days_from_now(expires_at)

    "Your link will expire after #{days} #{inflect(days, "day", "days")}."
  end

  defp expiration_message(%Link{max_views: max_views, expires_at: expires_at}) do
    days = days_from_now(expires_at)

    "Your link will expire after #{max_views} #{inflect(max_views, "view", "views")} or #{days} #{inflect(days, "day", "days")}."
  end

  defp inflect(1, singular, _plural), do: singular
  defp inflect(_, _singular, plural), do: plural
end
