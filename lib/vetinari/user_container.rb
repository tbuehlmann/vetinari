module Vetinari
  # The UserList class holds information about users a Thaum is able to see
  # in channels.
  class UserContainer
    include Celluloid

    attr_reader :users

    exclusive

    def initialize
      @users = Set.new
    end

    def add(user)
      @users << user
    end

    # TODO
    def remove(user)
      @users.delete(user)
    end

    # Find a User given the nick.
    def [](user_or_nick)
      case user_or_nick
      when User
        user_or_nick if @users.include?(user_or_nick)
      when String
        @users.find do |u|
          u.nick.downcase == user_or_nick.downcase
        end
      end
    end

    def has_user?(user)
      self[user] ? true : false
    end

    def clear
      @users.clear
    end

    # Removes all users from the UserContainer that don't share channels with
    # the Bot.
    def kill_zombie_users(users)
      (@users - users).each do |user|
        @users.delete(user) unless user.bot?
      end
    end
  end
end
