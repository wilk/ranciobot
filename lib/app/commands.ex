defmodule App.Commands do
  use App.Router
  use App.Commander

  alias App.Commands.Admin
  alias App.Commands.User

  # general help
  command "start", User, :start
  command "help", User, :help

  # menu
  command "menu", User, :menu_command
  callback_query_command "menu", User, :menu_callback
  
  # user order
  callback_query_command "add", User, :add_dish
  inline_query_command "rimuovi", User, :remove_dish_query
  command "add", User, :add_custom_dish
  command "rm", User, :remove_dish
  command "mia_nocciolina", User, :my_order

  # admin features
  command "help_admin", Admin, :help
  command "set_primi", Admin, :set_first
  command "set_secondi", Admin, :set_second
  command "set_contorni", Admin, :set_side
  command "add_user", Admin, :add_user
  inline_query_command "remove_user", Admin, :remove_user_query
  command "remove_user", Admin, :remove_user
  command "set_admin", Admin, :set_admin
  inline_query_command "unset_admin", Admin, :unset_admin_query
  command "unset_admin", Admin, :unset_admin
  command "list_users", Admin, :list_users
  command "list_admins", Admin, :list_admins
  command "generate_order", Admin, :generate_final_order

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
