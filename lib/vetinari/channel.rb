module Vetinari
  # Data structure which is used for storing users:
  # {lower_cased_nick => {User => [modes]}}
  #
  # Example:
  # {'ponder' => {:user => #<User nick="Ponder">, :modes => ['v', 'o']}}
  #
  # TODO: Actor?
  class Channel
    include Celluloid

    attr_reader :name, :users, :users_with_modes, :modes, :lists

    def initialize(name, bot)
      @name = name
      @bot = bot
      @users = Set.new
      @users_with_modes = {}
      @modes = {}
      @lists = Hash.new { |hash, key| hash[key] = [] }
      @mutex = Mutex.new
    end

    # Experimental, no tests so far.
    # def topic
    #   if @topic
    #     @topic
    #   else
    #     connected do
    #       fiber = Fiber.current
    #       callbacks = {}
    #       [331, 332, 403, 442].each do |numeric|
    #         callbacks[numeric] = @thaum.on(numeric) do |event_data|
    #           topic = event_data[:params].match(':(.*)').captures.first
    #           fiber.resume topic
    #         end
    #       end

    #       @bot.raw "TOPIC #{@name}"
    #       @topic = Fiber.yield
    #       callbacks.each do |type, callback|
    #         @thaum.callbacks[type].delete(callback)
    #       end

    #       @topic
    #     end
    #   end
    # end

    def topic=(topic)
      @bot.raw "TOPIC #{@name} :#{topic}"
    end

    def ban(hostmask)
      mode '+b', hostmask
    end

    def unban(hostmask)
      mode '-b', hostmask
    end

    def lock(key)
      @bot.raw "MODE #{@name} +k #{key}"
    end

    def unlock
      key = @modes['k']
      @bot.raw "MODE #{@name} -k #{key}" if key
    end

    def kick(user, reason = nil)
      if reason
        @bot.raw "KICK #{@name} #{user.nick} :#{reason}"
      else
        @bot.raw "KICK #{@name} #{user.nick}"
      end
    end

    def invite(user)
      @bot.raw "INVITE #{@name} #{user.nick}"
    end

    def op(user)
      mode '+o', user.nick
    end

    def deop(user)
      mode '-o', user.nick
    end

    def voice(user_or_nick)
      mode '+v', user.nick
    end

    def devoice(user_or_nick)
      mode '-v', user.nick
    end

    def join(key = nil)
      if @bot.channels.has_channel?(@name)
        return Future.new { :already_joined }
      end

      actor = Actor.current
      callbacks = Set.new

      callbacks << @bot.on(:join) do |env|
        if env[:channel].name == @name
          actor.signal(:join, :joined)
          callbacks.each { |cb| cb.remove_and_terminate }
        end
      end

      raw_messages = {
        475 => :locked,
        471 => :full,
        474 => :banned,
        473 => :invite_only
      }

      raw_messages.each do |raw, msg|
        callbacks << @bot.on(raw) do |env|
          channel_name = env[:params].split(' ')[1]

          if channel_name == @name
            actor.signal(:join, msg)
            callbacks.each { |cb| cb.remove_and_terminate }
          end
        end
      end

      after(5) do
        actor.signal(:join, :timeout)
        callbacks.each { |cb| cb.remove_and_terminate }
      end

      if key
        @bot.raw "JOIN #{@name} #{key}"
      else
        @bot.raw "JOIN #{@name}"
      end

      Future.new { actor.wait(:join) }
    end

    def part(message = nil)
      if message
        @bot.raw "PART #{@name} :#{message}"
      else
        @bot.raw "PART #{@name}"
      end
    end

    def hop(message = nil)
      key = @modes['k']
      part message
      join key
    end

    def add_user(user, modes = [])
      @mutex.synchronize do
        @users << user
        @users_with_modes[user] = modes
      end
    end

    def remove_user(user)
      @mutex.synchronize do
        @users_with_modes.delete(user)
        @users.delete?(user) ? user : nil
      end
    end

    def has_user?(user)
      @users.include?(user)
    end

    # def find_user(user)
    #   case user_or_nick
    #   when String
    #     @users.find { |u| u.nick.downcase == user_or_nick.downcase }
    #   when User
    #     has_user?(user_or_nick) ? user_or_nick : nil
    #   end
    # end

    # def find_user_with_modes(user_or_nick)
    #   user = case user_or_nick
    #   when String
    #     @users.find { |u| u.nick.downcase == user_or_nick.downcase }
    #   when User
    #     has_user?(user_or_nick) ? user_or_nick : nil
    #   end

    #   {:user => user, :modes => @users_with_modes[user]} if user
    # end

    def modes_of(user)
      @users_with_modes[user] if has_user?(user)
    end

    # TODO
    def set_mode(mode, isupport)
      if isupport['PREFIX'].keys.include?(mode[:mode])
        user = find_user(mode[:param])
        if user
          case mode[:direction]
          when :'+'
            @users_with_modes[user] << mode[:mode]
          when :'-'
            @users_with_modes[user].delete(mode[:mode])
          end
        end
      elsif isupport['CHANMODES']['A'].include?(mode[:mode])
        case mode[:direction]
        when :'+'
          add_to_list(mode[:mode], mode[:param])
        when :'-'
          remove_from_list(mode[:mode], mode[:param])
        end
      elsif isupport['CHANMODES']['B'].include?(mode[:mode])
        case mode[:direction]
        when :'+'
          set_channel_mode(mode[:mode], mode[:param])
        when :'-'
          unset_channel_mode(mode[:mode])
        end
      elsif isupport['CHANMODES']['C'].include?(mode[:mode])
        case mode[:direction] 
        when :'+'
          set_channel_mode(mode[:mode], mode[:param])
        when :'-'
          unset_channel_mode(mode[:mode])
        end
      elsif isupport['CHANMODES']['D'].include?(mode[:mode])
        case mode[:direction] 
        when :'+'
          set_channel_mode(mode[:mode], true)
        when :'-'
          unset_channel_mode(mode[:mode])
        end
      end
    end

    def mode(modes, params = nil)
      if params
        @bot.raw "MODE #{@name} #{modes} #{params}"
      else
        @bot.raw "MODE #{@name} #{modes}"
      end
    end

    def get_mode
      @bot.raw "MODE #{@name}"
    end

    def message(message)
      @bot.raw "PRIVMSG #{@name} :#{message}"
    end

    def inspect
      "#<Channel name=#{@name.inspect}>"
    end

    def to_s
      @name
    end

    private

    def set_channel_mode(mode, param)
      @modes[mode] = param
    end

    def unset_channel_mode(mode)
      @modes.delete(mode)
    end

    def add_to_list(list, param)
      @mutex.synchronize do
        @lists[list] ||= []
        @lists[list] << param
      end
    end

    def remove_from_list(list, param)
      @mutex.synchronize do
        if @lists[list].include?(param)
          @lists[list].delete(param)
        end
      end
    end
  end
end
