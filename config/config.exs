use Mix.Config

config :app,
  bot_name: System.get_env("BOT_NAME"),
  bot_owner: System.get_env("BOT_OWNER")

config :nadia,
  token: System.get_env("BOT_TOKEN")
