defmodule App.Commands do
  use App.Router
  use App.Commander

  alias App.Commands.Ranciobot

  # general help
  command "start", Ranciobot, :start
  command "help", Ranciobot, :help

  # menu
  command "menu", Ranciobot, :menu_command
  callback_query_command "menu", Ranciobot, :menu_callback
  
  # user order
  callback_query_command "add", Ranciobot, :add_dish
  inline_query_command "rimuovi", Ranciobot, :remove_dish_query
  command "add", Ranciobot, :add_custom_dish
  command "rm", Ranciobot, :remove_dish
  command "mia_nocciolina", Ranciobot, :my_order

  # admin features
  command "set_primi", Ranciobot, :set_first
  command "set_secondi", Ranciobot, :set_second
  command "set_contorni", Ranciobot, :set_side
  command "add_user", Ranciobot, :add_user
  command "remove_user", Ranciobot, :remove_user
  command "add_admin", Ranciobot, :add_admin
  command "remove_admin", Ranciobot, :remove_admin
  command "list_users", Ranciobot, :list_users
  command "list_admins", Ranciobot, :list_admins
  command "generate_order", Ranciobot, :generate_final_order

  # Rescues any unmatched callback query.
  callback_query do
    Logger.log :warn, "Did not match any callback query"

    answer_callback_query text: "Scusa, ma non ho capito."
  end

  # Rescues any unmatched inline query.
  inline_query do
    Logger.log :warn, "Did not match any inline query"
  end

  # The `message` macro must come at the end since it matches anything.
  # You may use it as a fallback.
  message do
    Logger.log :warn, "Did not match the message"

    send_message "Scusa, ma non ho capito."
  end
end
