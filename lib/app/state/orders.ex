defmodule App.State.Orders do
  use Agent
  @initial_state %{}

  def start_link() do
    Agent.start_link(fn() -> @initial_state end, name: :orders)
  end

  # add a new dish to the user's order
  def add(username, dish) do
    Agent.update(:orders, fn(state) ->
      Map.update(state, username, [dish], &(&1 ++ [dish]))
    end)
  end

  # remove an existing dish from the user's order
  def remove(username, dish) do
    Agent.update(:orders, fn(state) ->
      Map.update(state, username, [], &(&1 -- [dish]))
    end)
  end

  # get the whole order
  def get_order() do
    Agent.get(:orders, fn(state) -> state end)
  end

  # get the given user's order
  def get_order(username) do
    order = Agent.get(:orders, fn(state) -> state end)
    order[username]
  end

  # reset the current order
  def reset() do
    Agent.update(:orders, fn(_) -> @initial_state end)
  end
end
