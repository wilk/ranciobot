defmodule App.State.Orders do
  use Agent
  @initial_state %{}

  def start_link() do
    Agent.start_link(fn() -> @initial_state end, name: :orders)
  end

  def add(username, dish) do
    Agent.update(:orders, fn(state) ->
      order = state[String.to_atom(username)]
      order = if order == nil do
        [dish]
      else
        order ++ [dish]
      end

      %{state | String.to_atom(username): order}
    end)
  end

  def rm() do

  end

  def get_order() do

  end
end