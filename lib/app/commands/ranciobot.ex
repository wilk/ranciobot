defmodule App.Commands.Ranciobot do
  use App.Commander
  alias App.State.Menu
  alias App.State.Orders

  # common features
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

  def help(update) do
    Logger.info "Command /help"
    IO.inspect update

    send_message """
    Povero, hai già dimenticato come usarmi?

    Prova a digitare "*/menu*" per vedere cosa potresti mangiare oggi e poi niente: clicca sui vari bottoni e vedrai che qualcosa aggiungi al tuo ordine
    Ah si, e se vuoi vedere il tuo ordine digita "*/mia_nocciolina*"
    Se invece hai ripensamenti perché sei diversamente ricco, digita "*@ranciobot /rimuovi <piatto>*" così non dovrai lavari i piatti dopo esserti rifocillato

    Come al solito, *il menu è pronto circa per le 11:00 mentre non accetto più ordini dalle 11:40 in poi*

    Per tutto il resto c'è Mastercard
    """, parse_mode: "Markdown"
  end

  def menu_command(update) do
    Logger.info "Command /menu"

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
  end

  defp build_inline_menu(getter) do
    getter.() 
      |> Enum.map(&(%{callback_data: "/add #{&1}", text: &1}))
      |> Stream.chunk_every(3)
      |> Enum.to_list()
  end

  def menu_callback(update) do
    Logger.info "Callback /menu"

    action = String.replace(update.callback_query.data, "/menu ", "")

    case action do
      "primi" ->
        send_message """
        Primi piatti:
        """, reply_markup: %Model.InlineKeyboardMarkup{
            inline_keyboard: build_inline_menu(&Menu.get_first/0)
          }
      "secondi" ->
        send_message """
        Secondi piatti:
        """, reply_markup: %Model.InlineKeyboardMarkup{
            inline_keyboard: build_inline_menu(&Menu.get_second/0)
          }
      "contorni" ->
        send_message """
        Contorni:
        """, reply_markup: %Model.InlineKeyboardMarkup{
            inline_keyboard: build_inline_menu(&Menu.get_side/0)
          }
    end
  end

  def add_dish(update) do
    Logger.info "Callback /add"

    dish = String.replace(update.callback_query.data, "/add ", "")

    Orders.add(update.callback_query.from.username, dish)
    dishes = Orders.get_order(update.callback_query.from.username) |> Enum.join("\n - ")

    send_message "#{dish} aggiunto all'ordine!\nLa tua nocciolina attualmente è composta da:\n#{dishes}", parse_mode: "Markdown"
  end

  def remove_dish_query(update) do
    Logger.info "Inline Query Command /rimuovi"

    IO.inspect(update)

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

  def remove_dish(update) do
    Logger.info "Command /rm"

    dish = String.replace(update.message.text, "/rm ", "")

    Orders.remove(update.message.from.username, dish)

    dishes = Orders.get_order(update.message.from.username) |> Enum.join("\n - ")

    send_message "#{dish} rimosso dall'ordine!\nLa tua nocciolina attualmente è composta da:\n#{dishes}", parse_mode: "Markdown"
  end

  def my_order(update) do
    Logger.info "Command /mia_nocciolina"

    dishes = Orders.get_order(update.message.from.username) |> Enum.join("\n - ")

    send_message "La tua nocciolina è composta da:\n#{dishes}"
  end

  # Admin features
  defp set_dishes(message, prefix, setter) do
    message
      |> String.replace(prefix, "")
      |> String.trim()
      |> String.split(",")
      |> setter.()
  end

  defp check_auth?(username) do
    Enum.member?(Application.get_env(:app, :admin_list), username)
  end

  def set_first(update) do
    Logger.info "Command /set_primi"

    if check_auth?(update.message.from.username) do
      set_dishes(update.message.text, "/set_primi ", &Menu.set_first/1)

      send_message "Primi piatti inseriti!"
    else
      send_message "Uè giargiana, ma sai leggere o ti devo incidere la scritta \"Admin only\" sulla fronte?"
    end
  end

  def set_second(update) do
    Logger.info "Command /set_secondi"

    if check_auth?(update.message.from.username) do
      set_dishes(update.message.text, "/set_secondi ", &Menu.set_second/1)

      send_message "Secondi piatti inseriti!"
    else
      send_message "Uè giargiana, ma sai leggere o ti devo incidere la scritta \"Admin only\" sulla fronte?"
    end
  end

  def set_side(update) do
    Logger.info "Command /set_contorni"

    if check_auth?(update.message.from.username) do
      set_dishes(update.message.text, "/set_contorni ", &Menu.set_side/1)
      
      send_message "Contorni inseriti!"
    else
      send_message "Uè giargiana, ma sai leggere o ti devo incidere la scritta \"Admin only\" sulla fronte?"
    end
  end
end
