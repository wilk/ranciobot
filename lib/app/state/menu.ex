defmodule App.State.Menu do
  use Agent
  
  @initial_state %{first: ["Pennette Vodka", "Aglio olio pepe", "Cacio pepe", "Arrabbiata", "Niente"], secondi: [], side: []}

  def start_link() do
    Agent.start_link(fn() -> @initial_state end, name: :menu)
  end

  def set_first(dishes) do
    Agent.update(:menu, fn(state) -> %{state | first: dishes} end)
  end

  def set_second(dishes) do
    Agent.update(:menu, fn(state) -> %{state | second: dishes} end)
  end

  def set_side(dishes) do
    Agent.update(:menu, fn(state) -> %{state | side: dishes} end)
  end

  def get_first() do
    Agent.get(:menu, fn(state) -> state.first end)
  end

  def get_second() do
    Agent.get(:menu, fn(state) -> state.second end)
  end

  def get_side() do
    Agent.get(:menu, fn(state) -> state.side end)
  end

  def reset() do
    Agent.update(:menu, fn(state) -> @initial_state end)
  end
end
