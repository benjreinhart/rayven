defmodule Rayven.ShareLinks.LinkTest do
  use Rayven.DataCase

  import Rayven.ShareLinksFixtures
  import Rayven.TestUtils, only: [update_link: 2]

  alias Rayven.ShareLinks.Link

  test "expired?/1" do
    active_link = link_fixture(%{expires_at: expires(1)})
    expired_link = link_fixture(%{expires_at: expires(-1)})
    refute Link.expired?(active_link)
    assert Link.expired?(expired_link)
  end

  test "viewable?/1" do
    link = link_fixture(%{max_views: 1})

    assert 0 == link.views
    assert 1 == link.max_views
    assert Link.viewable?(link)

    link = update_link(link, views: 1)

    assert 1 == link.views
    assert 1 == link.max_views
    refute Link.viewable?(link)
  end
end
