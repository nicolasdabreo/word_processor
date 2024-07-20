import Config

config :word_processor, WordWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "GR9umAeZJTFQASRKU7MZtZc7jXNiRr8EGocQH3hrAZrNqT7YsjzhT5KxkbYqK+Cj",
  server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime
