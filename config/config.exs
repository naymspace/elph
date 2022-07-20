# General application configuration
import Config
# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

if config_env() == :test do
  import_config "test.exs"
end
