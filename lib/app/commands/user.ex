defmodule App.Commands.User do
  use App.Commander
  alias App.State.Menu
  alias App.State.Orders
  alias App.State.Users

  @kitchen_closed_message "🖕 La cucina è chiusa... get lost! 🖕"
  @guests_message "🖕 Bot disponibile solo per utenti registrati 🖕"

  # bot presentation
  def start(update) do
    Logger.info "Command /start"

    if Users.is_member?(:user, update.message.from.username) do
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
    else
      send_message @guests_message
    end
  end
  
  # general help
  def help(update) do
    Logger.info "Command /help"

    if Users.is_member?(:user, update.message.from.username) do
      send_message """
      Povero, hai già dimenticato come usarmi?

      Prova a digitare "*/menu*" per vedere cosa potresti mangiare oggi e poi niente: clicca sui vari bottoni e vedrai che qualcosa aggiungi al tuo ordine
      Ah si, e se vuoi vedere il tuo ordine digita "*/mia_nocciolina*"
      Se invece hai ripensamenti perché sei diversamente ricco, digita "*@ranciobot /rimuovi <piatto>*" così non dovrai lavari i piatti dopo esserti rifocillato

      Come al solito, *il menu è pronto circa per le 11:00 mentre non accetto più ordini dalle 11:40 in poi*

      Per tutto il resto c'è Mastercard
      """, parse_mode: "Markdown"
    else
      send_message @guests_message
    end
  end

  # list 3 action buttons, one for each type (first, second and side dishes)
  def menu_command(update) do
    Logger.info "Command /menu"

    if Users.is_member?(:user, update.message.from.username) do
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
    else
      send_message @guests_message
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

    if Users.is_member?(:user, update.callback_query.from.username) do
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
    else
      send_message @guests_message
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

    if Users.is_member?(:user, update.callback_query.from.username) do
      dish = String.replace(update.callback_query.data, "/add ", "") |> String.trim()
      add_dish(dish, update.callback_query.from.username, update)
    else
      send_message @guests_message
    end
  end

  # add a custom dish to the user's order
  def add_custom_dish(update) do
    Logger.info "Command /add"

    if Users.is_member?(:user, update.message.from.username) do
      dish = String.replace(update.message.text, "/add ", "") |> String.trim()
      add_dish(dish, update.message.from.username, update)
    else
      send_message @guests_message
    end
  end

  # list all the dishes selected by the user so they can remove it
  def remove_dish_query(update) do
    Logger.info "Inline Query Command /rimuovi"

    if Users.is_member?(:user, update.inline_query.from.username) do
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
    else
      send_message @guests_message
    end
  end

  # remove a dish from the user's order
  def remove_dish(update) do
    Logger.info "Command /rm"

    if Users.is_member?(:user, update.message.from.username) do
      if Menu.is_ready? do
        dish = String.replace(update.message.text, "/rm ", "")
        Orders.remove(update.message.from.username, dish)
        dishes = Orders.get_order(update.message.from.username) |> Enum.join("\n - ")
        send_message "#{dish} rimosso dall'ordine!\nLa tua nocciolina attualmente è composta da:\n - #{dishes}", parse_mode: "Markdown"
      else
        send_message @kitchen_closed_message
      end
    else
      send_message @guests_message
    end
  end

  # get the user's order
  def my_order(update) do
    Logger.info "Command /mia_nocciolina"

    if Users.is_member?(:user, update.message.from.username) do
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
    else
      send_message @guests_message
    end
  end
end
