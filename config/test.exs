use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :elph, ElphWeb.Test.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :elph, ecto_repos: [Elph.Test.Repo]

config :elph, Elph.Test.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: System.get_env("DATABASE_URL")

config :elph, repo: Elph.Test.Repo
