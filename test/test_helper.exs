children = [Elph.Test.Repo, ElphWeb.Test.Endpoint]
opts = [strategy: :one_for_one, name: Elph.Supervisor]
Supervisor.start_link(children, opts)

ExUnit.start(exclude: [:skip])
Ecto.Adapters.SQL.Sandbox.mode(Elph.Test.Repo, :manual)
