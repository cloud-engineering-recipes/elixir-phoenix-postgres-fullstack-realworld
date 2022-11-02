import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :realworld, RealWorld.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "realworld_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :realworld, RealWorldWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "I6PT6txl0Sh2QCxBlbJv24JMsWitpnYCkd6D5J5GnuswZktZjgq+E2xF+io8dozo",
  server: false

# In test we don't send emails.
config :realworld, RealWorld.Mailer, adapter: Swoosh.Adapters.Test

config :logger, backends: []

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
