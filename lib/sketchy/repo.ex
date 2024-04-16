defmodule Sketchy.Repo do
  use Ecto.Repo,
    otp_app: :sketchy,
    adapter: Ecto.Adapters.Postgres
end
