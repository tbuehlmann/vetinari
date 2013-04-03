module Vetinari
  class User
    attr_reader :nick
    
    def initialize(nick, bot)
      @nick = nick
      @bot = bot
    end

    # Updates the properties of an user.
    # def whois
    #   connected do
    #     fiber = Fiber.current
    #     callbacks = {}

    #     # User is online.
    #     callbacks[311] = @thaum.on(311) do |event_data|
    #       nick = event_data[:params].split(' ')[1]
    #       if nick.downcase == @nick.downcase
    #         @online = true
    #         # TODO: Add properties.
    #       end
    #     end

    #     # User is not online.
    #     callbacks[401] = @thaum.on(401) do |event_data|
    #       nick = event_data[:params].split(' ')[1]
    #       if nick.downcase == @nick.downcase
    #         @online = false
    #         fiber.resume
    #       end
    #     end

    #     # End of WHOIS.
    #     callbacks[318] = @thaum.on(318) do |event_data|
    #       nick = event_data[:params].split(' ')[1]
    #       if nick.downcase == @nick.downcase
    #         fiber.resume
    #       end
    #     end

    #     raw "WHOIS #{@nick}"
    #     Fiber.yield

    #     callbacks.each do |type, callback|
    #       @thaum.callbacks[type].delete(callback)
    #     end
    #   end

    #   self
    # end

    def online?
      if @bot.users[@nick]
        @online = true
      else
        # TODO
        # whois if @online.nil?
        # @online
      end
    end

    # TODO
    def bot?
      self == @bot.user
    end

    def dcc_send(filepath, filename = nil)
      if @bot.server_manager
        if File.exist?(filepath)
          filename = File.basename(filepath) unless filename
          @bot.server_manager.add_offering(self, filepath, filename)
        else
          raise "File '#{filepath}' does not exist."
        end
      else
        raise 'DCC not available: Missing external IP or ports'
      end
    end

    def message(message)
      @bot.raw "PRIVMSG #{@nick} :#{message}"
    end

    def notice(message)
      @bot.raw "NOTICE #{@nick} :#{message}"
    end

    def inspect
      "#<User nick=#{@nick.inspect}>"
    end
  end
end
