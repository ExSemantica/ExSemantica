import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :exsemantica, Exsemantica.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "exsemantica_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# English locale by default
config :gettext, default_locale: "en"
