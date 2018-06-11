defmodule App.State.Orders do
  use Agent
  @initial_state %{}

  def start_link() do
    Agent.start_link(fn() -> @initial_state end, name: :orders)
  end

  def add(username, dish) do
    Agent.update(:orders, fn(state) ->
      dishes = state[username]
      dishes = if dishes == nil do
        []
      end

      Map.put(state, username, dishes ++ [dish])
    end)
  end

  def remove(username, dish) do
    Agent.update(:orders, fn(state) ->
      dishes = state[username]
      if dishes == nil do
        state
      else
        Map.put(state, username, dishes -- [dish])
      end
    end)
  end

  def get_order() do
    Agent.get(:orders, fn(state) -> state end)
  end

  def get_order(username) do
    order = Agent.get(:orders, fn(state) -> state end)
    order[username]
  end
end
