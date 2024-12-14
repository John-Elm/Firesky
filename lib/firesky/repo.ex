defmodule Firesky.Repo do
  use Ecto.Repo,
    otp_app: :firesky,
    adapter: Ecto.Adapters.Postgres
end
