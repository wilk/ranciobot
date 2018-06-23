defmodule App.Commands.Ranciobot do
  use App.Commander
  alias App.State.Menu
  alias App.State.Orders
  alias App.State.Users

  @kitchen_closed_message "🖕 La cucina è chiusa... get lost! 🖕"
  @admin_not_allowed_message "🤜 Uè giargiana, ma sai leggere o ti devo incidere la scritta \"Admin only\" sulla fronte? 🤛"  

  # todo: split this file into two files, one for users and one for admins
  ### USERS FEATURES ###
  
  # bot presentation
  def start(update) do
    Logger.info "Command /start"

    send_message """
    Ciao, piccolo Oliver Twist affamato!
    Se sei qui per avere la tua razione di zuppa, armati di una ciotola e sfoggia il tuo miglior sorriso: oggi mangerai!
    
    Per vedere cosa passa il convento quest'oggi, scrivi "*/menu*" e magicamente compariranno 3 bottoni a prova di scemo: servono per mostrare la lista dei primi, dei secondi e dei contorni
    Se vuoi aggiungere una pietanza al tuo ordine, non devi far altro che cliccare su una di esse e, sempre come per magia, il tuo ordine si popolerà! Figo eh?

    Per vedere quel che mangerai oggi, digita "*/mia_nocciolina*" (https://www.youtube.com/watch?v=f4j1Y67A1lE)

    Nel caso fossi troppo affamato ma ancora povero come la merda, puoi sempre rimuovere un piatto, digitando "*@ranciobot rimuovi <piatto>*"

    Che altro dirti?
    Beh, *il menu è pronto circa per le 11:00 mentre non accetto più ordini dalle 11:40 in poi*, nemmeno se mi prometti un bacino
    Invierò quindi l'ordine al mio padrone (Wilk) o un suo fidato delegato e se non avrai fatto in tempo a ordinare, sticazzi: niente senza pane dovrà bastarti!
    """, parse_mode: "Markdown"
  end

  # general help
  def help(update) do
    Logger.info "Command /help"

    send_message """
    Povero, hai già dimenticato come usarmi?

    Prova a digitare "*/menu*" per vedere cosa potresti mangiare oggi e poi niente: clicca sui vari bottoni e vedrai che qualcosa aggiungi al tuo ordine
    Ah si, e se vuoi vedere il tuo ordine digita "*/mia_nocciolina*"
    Se invece hai ripensamenti perché sei diversamente ricco, digita "*@ranciobot /rimuovi <piatto>*" così non dovrai lavari i piatti dopo esserti rifocillato

    Come al solito, *il menu è pronto circa per le 11:00 mentre non accetto più ordini dalle 11:40 in poi*

    Per tutto il resto c'è Mastercard
    """, parse_mode: "Markdown"
  end

  # list 3 action buttons, one for each type (first, second and side dishes)
  def menu_command(update) do
    Logger.info "Command /menu"

    if Menu.is_ready? do
      send_message """
    Menu del giorno:
    """, reply_markup: %Model.InlineKeyboardMarkup{
        inline_keyboard: [
          [
            %{
              callback_data: "/menu primi",
              text: "Primi 🍝",
            },
          ],
          [
            %{
              callback_data: "/menu secondi",
              text: "Secondi 🍖",
            },
            %{
              callback_data: "/menu contorni",
              text: "Contorni 🥗",
            },
          ]
        ]
      }
    else
      send_message @kitchen_closed_message
    end
  end

  # common function for generating the action buttons for the choosen menu type 
  defp build_inline_menu(getter) do
    getter.() 
      |> Enum.map(&(%{callback_data: "/add #{&1}", text: &1}))
      |> Stream.chunk_every(3)
      |> Enum.to_list()
  end

  # list the choosen menu type
  def menu_callback(update) do
    Logger.info "Callback /menu"

    action = String.replace(update.callback_query.data, "/menu ", "")

    case action do
      "primi" ->
        if Menu.is_ready? do
          send_message """
        Primi piatti 🍝:
        """, reply_markup: %Model.InlineKeyboardMarkup{
            inline_keyboard: build_inline_menu(&Menu.get_first/0)
          }
        else
          send_message @kitchen_closed_message
        end
      "secondi" ->
        if Menu.is_ready? do
          send_message """
        Secondi piatti 🍖:
        """, reply_markup: %Model.InlineKeyboardMarkup{
            inline_keyboard: build_inline_menu(&Menu.get_second/0)
          }
        else
          send_message @kitchen_closed_message
        end
      "contorni" ->
        if Menu.is_ready? do
          send_message """
        Contorni 🥗:
        """, reply_markup: %Model.InlineKeyboardMarkup{
            inline_keyboard: build_inline_menu(&Menu.get_side/0)
          }
        else
          send_message @kitchen_closed_message
        end
    end
  end

  defp add_dish(dish, username, update) do
    user_dishes = Orders.get_order(username)

    cond do
      !Menu.is_ready? ->
        send_message @kitchen_closed_message
      user_dishes == nil or length(user_dishes) == 0 or !Enum.member?(user_dishes, dish) ->
        Orders.add(username, dish)
        dishes = Orders.get_order(username) |> Enum.join("\n - ")
        send_message "Il piatto \"#{dish}\" è stato aggiunto all'ordine!\nLa tua nocciolina attualmente è composta da:\n - #{dishes}", parse_mode: "Markdown"
      Enum.member?(user_dishes, dish) ->
        dishes = user_dishes |> Enum.join("\n - ")
        send_message "Il piatto \"#{dish}\" è già presente nel tuo ordine!\nLa tua nocciolina attualmente è composta da:\n - #{dishes}", parse_mode: "Markdown"
    end
  end

  # add a dish to the user's order
  def add_dish(update) do
    Logger.info "Callback /add"

    dish = String.replace(update.callback_query.data, "/add ", "") |> String.trim()
    add_dish(dish, update.callback_query.from.username, update)
  end

  # add a custom dish to the user's order
  def add_custom_dish(update) do
    Logger.info "Callback /add"

    dish = String.replace(update.message.text, "/add ", "") |> String.trim()
    add_dish(dish, update.message.from.username, update)
  end

  # list all the dishes selected by the user so they can remove it
  def remove_dish_query(update) do
    Logger.info "Inline Query Command /rimuovi"

    query = String.replace(update.inline_query.query, "/rimuovi ", "") |> String.downcase()
    Orders.get_order(update.inline_query.from.username)
      |> Enum.filter(&(String.contains?(String.downcase(&1), query)))
      |> Enum.map(&(%InlineQueryResult.Article{
        id: &1,
        title: &1,
        input_message_content: %{
          message_text: "/rm #{&1}",
        }
      }))
      |> answer_inline_query()
  end

  # remove a dish from the user's order
  def remove_dish(update) do
    Logger.info "Command /rm"

    if Menu.is_ready? do
      dish = String.replace(update.message.text, "/rm ", "")
      Orders.remove(update.message.from.username, dish)
      dishes = Orders.get_order(update.message.from.username) |> Enum.join("\n - ")
      send_message "#{dish} rimosso dall'ordine!\nLa tua nocciolina attualmente è composta da:\n - #{dishes}", parse_mode: "Markdown"
    else
      send_message @kitchen_closed_message
    end
  end

  # get the user's order
  def my_order(update) do
    Logger.info "Command /mia_nocciolina"

    if Menu.is_ready? do
      dishes = Orders.get_order(update.message.from.username)

      if dishes == nil or length(dishes) == 0 do
        send_message "Che dici? Cominciamo a ordinare qualcosa?"
      else
        msg = dishes |> Enum.join("\n - ")
        send_message "La tua nocciolina è composta da:\n - #{msg}"
      end
    else
      send_message @kitchen_closed_message
    end
  end

  ### ADMINS FEATURES ###

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
