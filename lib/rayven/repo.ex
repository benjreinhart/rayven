defmodule Rayven.Repo do
  use Ecto.Repo,
    otp_app: :rayven,
    adapter: Ecto.Adapters.SQLite3
end
