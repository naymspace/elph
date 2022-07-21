repo = Application.get_env(:elph, :repo)

elph_repo =
  case repo do
    Elph.Test.Repo -> [Elph.Test.Repo]
    _ -> []
  end

children = elph_repo ++ [ElphWeb.Test.Endpoint]
opts = [strategy: :one_for_one, name: Elph.Supervisor]
Supervisor.start_link(children, opts)

ExUnit.start(exclude: [:skip])
Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)
