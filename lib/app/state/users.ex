# State management for users and admins
defmodule App.State.Users do
  use Agent

  # todo: unify users and admins, giving to admins a special flag
  @initial_state [%{username: Application.get_env(:app, :bot_owner), is_admin?: true}]

  def start_link() do
    Agent.start_link(fn() -> @initial_state end, name: :users)
  end

  # list all the users
  def list(:user) do
    Agent.get(:users, fn(users) ->  
      users
        |> Enum.filter(&(!&1.is_admin?))
        |> Enum.map(&(&1.username))
    end)
  end

  # list all the admins
  def list(:admin) do
    Agent.get(:users, , fn(users) ->
      users
        |> Enum.filter(&(&1.is_admin?))
        |> Enum.map(&(&1.username))
    end)
  end

  # Add a new user to the list
  def add(:user, username) do
    Agent.update(:users, fn(users) ->
      if Enum.find(users, &(&1.username == username)) == nil do
        users ++ [%{username: username, is_admin?: false}]
      else
        users
      end
    end)
  end

  # Add a new admin to the list
  # todo: change this in "set_admin"
  def add(:admin, username) do
    Agent.update(:users, fn(users) ->
      if Enum.find(users, &(&1.username == username)) == nil do
        users ++ [%{username: username, is_admin?: true}]
      else
        users
      end
    end)
  end

  # Remove an existing user from the list
  def remove(:user, username) do
    Agent.update(:users, fn(users) ->
      user = Enum.find(users, &(&1.username == username))

      if user != nil do
        users -- [user]
      else
        users
      end
    end)
  end

  # Remove an existing admin from the list
  # @todo: convert into unset_admin
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

  # check if an user is already registered
  def is_member?(:user, username) do
    Agent.get(:users, fn(users) -> Enum.find(users, &(&.username == username)) != nil end)
  end

  # check if an user is an admin
  def is_member?(:admin, username) do
    Agent.get(:users, fn(users) -> 
      user = Enum.find(users, &(&.username == username))
      user != nil and user.is_admin?
    end)
  end
end
