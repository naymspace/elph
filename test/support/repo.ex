defmodule Elph.Test.Repo do
  use Ecto.Repo,
    otp_app: :elph,
    adapter: Ecto.Adapters.MyXQL
end
