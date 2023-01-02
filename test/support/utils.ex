defmodule Rayven.TestUtils do
  alias Rayven.Repo
  alias Rayven.ShareLinks.Link

  def update_link(link, attribute_kwargs) do
    import Ecto.Query, warn: false

    query =
      from l in Link,
        where: l.id == ^link.id,
        update: [set: ^attribute_kwargs],
        select: l

    {1, [link]} = Repo.update_all(query, [])

    link
  end
end
