module Vetinari
  module IRC
    def register
      raw "PASS #{@config.password}" if @config.password
      raw "NICK #{@config.nick}"
      raw "USER #{@config.username} * * :#{@config.real_name}"
    end

    def rename(nick)
      raw "NICK :#{nick}"
    end

    def away(message = nil)
      if message
        raw "AWAY :#{message}"
      else
        raw "AWAY"
      end
    end

    def back
      away
    end

    def quit(message = nil)
      @quitted = true

      if message
        raw "QUIT :#{message}"
      else
        raw 'QUIT'
      end
    end

    def join(channel_name, key = nil)
      unless @channels.has_channel?(channel_name)
        channel = Channel.new(channel_name, @actor)
        channel.join key
      end
    end
  end
end
