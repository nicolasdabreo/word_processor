import Config

config :word_processor, WordWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "+G7OPlUHIe2xNWI4FEj34bjtVu523m5NE9+sSU4JLZWNUP9TgI480lJOPsrO0cMg",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:word_processor, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:word_processor, ~w(--watch)]}
  ]

config :word_processor, WordWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/word_processor_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
config :phoenix_live_view, :debug_heex_annotations, true
