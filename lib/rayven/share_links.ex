defmodule Rayven.ShareLinks do
  @moduledoc """
  The ShareLinks context.
  """

  import Ecto.Query, warn: false

  alias Rayven.Repo
  alias Rayven.ShareLinks.Link

  def get_link!(id) do
    Repo.get!(Link, id)
  end

  def create_link!(attrs \\ %{}) do
    %Link{}
    |> Link.changeset(attrs)
    # returning: true will populate the link object with the DB values which includes values set by database defaults.
    |> Repo.insert!(returning: true)
  end

  @doc """
  Performs a 'view link' operation on a given link, which increments
  the view count and returns a tuple of {:ok, link}. If the Link doesn't
  exist, or the passphrase_digest doesn't match, or the Link has reached
  its max views, or it is expired (via expires_at column), then {:error, nil}
  is returned.
  """
  def view_link(id, passphrase_digest) do
    # Note: There are three important subtleties here worth calling out.
    #
    #     1. We must ensure that the view incrementing is atomic. If we
    #        were to naively read-modify-write, we can end up clobbering
    #        another concurrent write (unless we deploy transactions).
    #        Thus, this query uses an atomic write pattern, i.e., it
    #        runs the following update clause: `set views = views + 1`.
    #
    #     2. While 1) saves us from two concurrent writes stepping over
    #        one another, it DOES NOT save us from exceeding max_views.
    #        We can add a WHERE condition to select only records whose
    #        views are less than max_views, meaning there's at least
    #        one increment left, but again we have the potential for
    #        a race condition. We solve this case by defining a CHECK
    #        constraint on the views column that ensures views are LTE
    #        to max_views. We *rely* on this constraint to maintain
    #        data integrity even in the event of concurrent writes.
    #
    #     3. While 2) guarantees views will NOT exceed max_views, it has
    #        the potential to regularly cause a constraint violation which
    #        results in an exception. 'Regularly' because we currently run
    #        this query both for updating and _finding_ a link when a view
    #        request comes through. Therefore, we do add a WHERE condition
    #        to lookup a link that has a view count less than max_views so
    #        that the vast majority of the time no exceptions will be raised.
    #        This way, we optimistically go for the update and rely on the
    #        CHECK constraint to fail in the event of a race condition.
    #        Given the race condition should be rare, we're ok with an
    #        unhandled exception in that case.
    #
    query =
      from n in Link,
        where:
          n.id == ^id and
            n.passphrase_digest == ^passphrase_digest and
            n.views < n.max_views and
            ^NaiveDateTime.utc_now() < n.expires_at,
        update: [inc: [views: 1]],
        select: n

    case Repo.update_all(query, []) do
      {1, [link]} ->
        {:ok, link}

      {0, []} ->
        {:error, nil}
    end
  end
end
