# State management for users and admins
defmodule App.State.Users do
  use Agent

  @initial_state %{admins: [Application.get_env(:app, :bot_owner)], users: []}

  def start_link() do
    IO.inspect @initial_state
    Agent.start_link(fn() -> @initial_state end, name: :users)
  end

  # Add a new user to the list
  def add(:user, username) do
    Agent.update(:users, fn(state) ->
      users = if Enum.member?(state.users, username) do
        state.users
      else
        state.users ++ [username]
      end

      %{state | users: users}
    end)
  end

  # Add a new admin to the list
  def add(:admin, username) do
    Agent.update(:users, fn(state) ->
      admins = if Enum.member? state.admins, username do
        state.admins
      else
        state.admins ++ [username]
      end

      %{state | admins: admins}
    end)
  end

  # Remove an existing user from the list
  def remove(:user, username) do
    Agent.update(:users, fn(state) ->
      users = if Enum.member? state.users, username do
        state.users -- [username]
      else
        state.users
      end

      %{state | users: users}
    end)
  end

  # Remove an existing admin from the list
  def remove(:admin, username) do
    Agent.update(:users, fn(state) ->
      admins = if Enum.member? state.admins, username do
        state.admins -- [username]
      else
        state.admins
      end

      %{state | admins: admins}
    end)
  end

  # check if an user is member of the users list
  def is_member?(:user, username) do
    Agent.get(:users, fn(state) -> Enum.member?(state.users, username) end)
  end

  # check if an admin is member of the admins list
  def is_member?(:admin, username) do
    Agent.get(:users, fn(state) -> Enum.member?(state.admins, username) end)
  end
end
