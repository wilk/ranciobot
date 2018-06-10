defmodule App.Commands.Ranciobot do
  use App.Commander
  alias App.State.Menu

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
              text: "Primi",
            },
          ],
          [
            %{
              callback_data: "/menu secondi",
              text: "Secondi",
            },
            %{
              callback_data: "/menu contorni",
              text: "Contorni",
            },
          ]
        ]
      }
  end

  def menu_callback(update) do
    Logger.info "Callback /menu"

    action = String.replace(update.message.text, "/menu ", "")

    case action do
      "primi" ->
      "secondi" ->
      "contorni" ->
      _ -> 
        send_message """
        Menu del giorno:
        """, reply_markup: %Model.InlineKeyboardMarkup{
            inline_keyboard: [
              [
                %{
                  callback_data: "/menu primi",
                  text: "Primi",
                },
              ],
              [
                %{
                  callback_data: "/menu secondi",
                  text: "Secondi",
                },
                %{
                  callback_data: "/menu contorni",
                  text: "Contorni",
                },
              ]
            ]
          }
    end
  end

  def add_dish(update) do
    Logger.info "Callback /add"
  end

  def rm_dish(update) do
    Logger.info "Inline Query Command /rm"
  end

  def my_order(update) do
    Logger.info "Command /mia_nocciolina"
  end

  # Admin features
  def set_first(update) do
    Logger.info "Command /set_primi"

    update.message.text
      |> String.trim()
      |> String.split(",")
      |> Menu.set_first()
  end

  def set_second(update) do
    Logger.info "Command /set_secondi"

    update.message.text
      |> String.trim()
      |> String.split(",")
      |> Menu.set_second()
  end

  def set_side(update) do
    Logger.info "Command /set_contorni"

    update.message.text
      |> String.trim()
      |> String.split(",")
      |> Menu.set_side()
  end
end
