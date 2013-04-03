module Vetinari
  class ChannelContainer
    attr_reader :channels

    def initialize
      @channels = Set.new
      @mutex = Mutex.new
    end

    def add(channel)
      @mutex.synchronize do
        @channels << channel
      end
    end

    def [](channel_or_channel_name)
      case channel_or_channel_name
      when Channel
        if @channels.include?(channel_or_channel_name)
          channel_or_channel_name
        end
      when String
        @channels.find do |c|
          c.name.downcase == channel_or_channel_name.downcase
        end
      end
    end

    def has_channel?(channel)
      self[channel] ? true : false
    end

    def remove(channel)
      @mutex.synchronize do
        if has_channel?(channel)
          @channels.delete(channel)
        end
      end
    end

    # Removes a User from all Channels from the ChannelList.
    # Returning a Set of Channels in which the User was.
    def remove_user(user)
      @mutex.synchronize do
        channels = Set.new

        @channels.each do |channel|
          if channel.remove_user(user)
            channels << channel
          end
        end

        channels
      end
    end

    # Removes all Channels from the ChannelList and returns them.
    def clear
      @mutex.synchronize do
        channels = @channels.dup
        @channels.clear
        channels
      end
    end

    # Returns a Set of all Users that are in one of the Channels from the
    # ChannelList.
    def users
      users = Set.new

      @channels.each do |channel|
        users.merge(channel.users)
      end

      users
    end
  end
end