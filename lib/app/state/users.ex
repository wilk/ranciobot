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
    Agent.get(:users, fn(users) ->
      users
        |> Enum.filter(&(&1.is_admin?))
        |> Enum.map(&(&1.username))
    end)
  end

  # Add a new user to the list
  def add(username) do
    Agent.update(:users, fn(users) ->
      if Enum.find(users, &(&1.username == username)) == nil do
        users ++ [%{username: username, is_admin?: false}]
      else
        users
      end
    end)
  end

  # Add a new admin to the list
  def set_admin(username) do
    Agent.update(:users, fn(users) ->
      index = Enum.find_index(users, &(&1.username == username))

      if index != nil do
        user = Enum.at(users, index)
        List.update_at(users, index, %{user | is_admin?: true})
      else
        users
      end
    end)
  end

  # Remove an existing user from the list
  def remove(username) do
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
  def unset_admin(username) do
    Agent.update(:users, fn(users) ->
      index = Enum.find_index(users, &(&1.username == username))

      if index != nil do
        user = Enum.at(users, index)
        List.update_at(users, index, %{user | is_admin?: false})
      else
        users
      end
    end)
  end

  # check if an user is already registered
  def is_member?(:user, username) do
    Agent.get(:users, fn(users) -> Enum.find(users, &(&1.username == username)) != nil end)
  end

  # check if an user is an admin
  def is_member?(:admin, username) do
    Agent.get(:users, fn(users) -> 
      user = Enum.find(users, &(&1.username == username))
      user != nil and user.is_admin?
    end)
  end
end
