use Mix.Config

config :app,
  bot_name: System.get_env("BOT_NAME"),
  admin_list: System.get_env("ADMIN_LIST") |> String.split(",")

config :nadia,
  token: System.get_env("BOT_TOKEN")
