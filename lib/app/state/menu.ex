defmodule App.State.Menu do
  use Agent
  
  @initial_state %{first: [], second: [], side: [], ready: false}

  def start_link() do
    Agent.start_link(fn() -> @initial_state end, name: :menu)
  end

  # check if the current menu is ready or something is missing
  defp is_ready?(menu) do
    length(menu.first) > 0 and length(menu.second) > 0 and length(menu.side) > 0
  end

  # define first dishes
  def set_first(dishes) do
    Agent.update(:menu, fn(state) ->
      state = %{state | first: dishes}
      %{state | ready: is_ready? state}
    end)
  end

  # define second dishes
  def set_second(dishes) do
    Agent.update(:menu, fn(state) ->
      state = %{state | second: dishes}
      %{state | ready: is_ready? state}
    end)
  end

  # define side dishes
  def set_side(dishes) do
    Agent.update(:menu, fn(state) ->
      state = %{state | side: dishes}
      %{state | ready: is_ready? state}
    end)
  end

  # get first dishes
  def get_first() do
    Agent.get(:menu, &(&1.first))
  end

  # get second dishes
  def get_second() do
    Agent.get(:menu, &(&1.second))
  end

  # get side dishes
  def get_side() do
    Agent.get(:menu, &(&1.side))
  end

  def is_ready?() do
    Agent.get(:menu, &(&1.ready))
  end

  # reset current menu
  def reset() do
    Agent.update(:menu, fn(_) -> @initial_state end)
  end
end
