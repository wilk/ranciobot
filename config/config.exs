use Mix.Config

config :app,
  bot_name: System.get_env("BOT_NAME")

config :nadia,
  token: System.get_env("BOT_TOKEN")
