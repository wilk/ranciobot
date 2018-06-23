defmodule App.Commands.Admin do
  use App.Commander
  alias App.State.Menu
  alias App.State.Orders
  alias App.State.Users

  @admin_not_allowed_message "🤜 Uè giargiana, ma sai leggere o ti devo incidere la scritta \"Admin only\" sulla fronte? 🤛"  

  # admin help
  def help(update) do
    Logger.info "Command /help_admin"
    if Users.is_member?(:admin, update.message.from.username) do
      send_message """
      Per i potenti e forti amministratori come te, ecco cosa puoi farmi fare 🤘
      Le azioni si suddividono in definizione del *Menu* e gestione degli *Utenti*.

      Per popolare il menu, i seguenti comandi:
      - /set_primi Piatto1, Piatto2, Piatto3, ... : definisci i primi piatti del menu
      - /set_secondi Piatto1, Piatto2, Piatto3, ... : definisci i secondi piatti del menu
      - /set_contorni Piatto1, Piatto2, Piatto3, ... : definisci i contorni del menu

      Puoi infine generare l'ordine attraverso il comando */generate_order*.
      Con questo comando resetterai anche il Menu e l'Ordine, cancellandoli del tutto e chiudendo così la cucina.

      Per aggiungere utenti e admin, i seguenti comandi:
      - /add_user utente : aggiungi un utente
      - @ranciobot /remove_user <utente scelto> : rimuovi un utente
      - /add_admin utente : aggiungi un admin
      - @ranciobot /remove_admin <admin scelto> : rimuovi un admin
      - /list_users : mostra lista utenti
      - /list_admins : mostra lista admin

      Ricorda che gli admin sono utenti che possono gestire il menu, l'ordine e la lista di utenti e admin, oltre all'ordinare i piatti come gli altri utenti.
      """, parse_mode: "Markdown"
    else
      send_message @admin_not_allowed_message
    end
  end
  
  # common function to populate the menu types
  defp set_dishes(update, command_prefix, message_prefix, setter) do
    if Users.is_member?(:admin, update.message.from.username) do
      update.message.text
        |> String.replace(command_prefix, "")
        |> String.trim()
        |> String.split(",")
        |> setter.()
      
      {progress, ready} = Menu.get_progress()

      if ready do
        send_message "#{message_prefix} inseriti! Menu completato 💪"
      else
        send_message "#{message_prefix} inseriti!\nPer completare il menu ti manca da aggiungere: #{progress}"
      end
    else
      send_message @admin_not_allowed_message
    end
  end

  # populate first dishes
  def set_first(update) do
    Logger.info "Command /set_primi"

    set_dishes(update, "/set_primi ", "Primi piatti", &Menu.set_first/1)
  end

  # populate second dishes
  def set_second(update) do
    Logger.info "Command /set_secondi"

    set_dishes(update, "/set_secondi ", "Secondi piatti", &Menu.set_second/1)
  end

  # populate side dishes
  def set_side(update) do
    Logger.info "Command /set_contorni"

    set_dishes(update, "/set_contorni ", "Contorni", &Menu.set_side/1)
  end

  # generate the final order to send to the restaurant
  def generate_final_order(update) do
    Logger.info "Command /generate_order"

    if Users.is_member?(:admin, update.message.from.username) do
      order = Orders.get_order()

      dishes = Map.values(order)
        |> Enum.concat()
        |> Enum.map_reduce(%{}, fn(dish, acc) -> 
          {dish, Map.update(acc, dish, 1, &(&1 + 1))}
        end)
        |> Tuple.to_list()
        |> Enum.at(1)
        |> Enum.map_join("\n", fn({k,v}) -> 
          "- #{v} #{k}"
        end)
      
      send_message "L'ordine è:\n#{dishes}"

      Orders.reset()
      Menu.reset()
    else
      send_message @admin_not_allowed_message
    end
  end

  # add an user to the users list
  def add_user(update) do
    Logger.info "Command /add_user"

    if Users.is_member?(:admin, update.message.from.username) do
      username = update.message.text |> String.replace("/add_user ", "")
      Users.add(:user, username)

      send_message "#{username} aggiunto alla lista di utenti 🤘"
    else
      send_message @admin_not_allowed_message
    end
  end

  # list all the users an admin can remove
  def remove_user_query(update) do
    Logger.info "Inline Query Command /remove_user"

    query = String.replace(update.inline_query.query, "/remove_user ", "") |> String.downcase()
    Users.list(:user)
      |> Enum.filter(&(String.contains?(String.downcase(&1), query)))
      |> Enum.map(&(%InlineQueryResult.Article{
        id: &1,
        title: &1,
        input_message_content: %{
          message_text: "/remove_user #{&1}",
        }
      }))
      |> answer_inline_query()
  end

  # remove an user from the users list
  def remove_user(update) do
    Logger.info "Command /remove_user"

    if Users.is_member?(:admin, update.message.from.username) do
      username = update.message.text |> String.replace("/remove_user ", "")
      Users.remove(:user, username)

      send_message "#{username} rimosso dalla lista di user 👍"
    else
      send_message @admin_not_allowed_message
    end
  end

  # add an admin to the admins list
  def add_admin(update) do
    Logger.info "Command /add_admin"

    if Users.is_member?(:admin, update.message.from.username) do
      username = update.message.text |> String.replace("/add_admin ", "")
      Users.add(:admin, username)

      send_message "#{username} aggiunto alla lista di admin 🤘"
    else
      send_message @admin_not_allowed_message
    end
  end

  # list all the admins an admin can remove
  def remove_admin_query(update) do
    Logger.info "Inline Query Command /remove_admin"

    query = String.replace(update.inline_query.query, "/remove_admin ", "") |> String.downcase()
    Users.list(:admin)
      |> Enum.filter(&(String.contains?(String.downcase(&1), query)))
      |> Enum.map(&(%InlineQueryResult.Article{
        id: &1,
        title: &1,
        input_message_content: %{
          message_text: "/remove_admin #{&1}",
        }
      }))
      |> answer_inline_query()
  end

  # remove an admin from the admnins list
  def remove_admin(update) do
    Logger.info "Command /remove_admin"

    if Users.is_member?(:admin, update.message.from.username) do
      username = update.message.text |> String.replace("/remove_admin ", "")
      Users.remove(:admin, username)

      send_message "#{username} rimosso dalla lista di admin 👍"
    else
      send_message @admin_not_allowed_message
    end
  end

  # list available users
  def list_users(update) do
    Logger.info "Command /list_users"

    if Users.is_member?(:admin, update.message.from.username) do
      users = Users.list(:user) |> Enum.join("\n - ")

      send_message "Lista degli utenti registrati:\n - #{users}"
    else
      send_message @admin_not_allowed_message
    end
  end

  # list available admins
  def list_admins(update) do
    Logger.info "Command /list_admins"

    if Users.is_member?(:admin, update.message.from.username) do
      admins = Users.list(:admin) |> Enum.join("\n - ")

      send_message "Lista degli admin registrati:\n - #{admins}"
    else
      send_message @admin_not_allowed_message
    end
  end
end
