module Vetinari
  module IRC
    def register
      raw "NICK #{@config.nick}"
      raw "PASS #{@config.password}" if @config.password
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
  end
end
