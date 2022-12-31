defmodule RayvenWeb.LinkLive.Show do
  use RayvenWeb, :live_view

  alias Rayven.ShareLinks
  alias Rayven.ShareLinks.Link

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, link: ShareLinks.get_link!(id), viewing: false, error: nil)}
  end

  @impl true
  def handle_event(
        "view",
        %{"passphrase_digest" => passphrase_digest},
        %{assigns: %{link: link = %Link{}}} = socket
      ) do
    case ShareLinks.view_link(link.id, passphrase_digest) do
      {:ok, link} ->
        {:noreply, assign(socket, link: link, viewing: true)}

      {:error, nil} ->
        {:noreply, assign(socket, error: "Link does not exist or has expired")}
    end
  end
end
