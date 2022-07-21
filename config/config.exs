# General application configuration
use Mix.Config
# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

if Mix.env() == :test do
  import_config "test.exs"
end
