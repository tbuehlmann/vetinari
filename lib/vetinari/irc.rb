module Vetinari
  module IRC
    def register
      raw "PASS #{@config.password}" if @config.password
      raw "NICK #{@config.nick}"
      raw "USER #{@config.username} * * :#{@config.real_name}"
    end

    def rename(nick)
      if nick.length > @config.isupport['NICKLEN']
        nick = nick.slice(0, @config.isupport['NICKLEN'])
      end

      return Celluloid::Future.new { nick } if @user.nick == nick

      condition = Celluloid::Condition.new
      callbacks = Set.new

      callbacks << on(:nick_change) do |env|
        if env[:user].bot?
          condition.signal env[:user].nick
          callbacks.each { |cb| cb.remove_and_terminate if cb.alive? }
        end
      end

      raw_messages = {
        432 => :erroneous_nickname,
        433 => :nickname_in_use
      }

      raw_messages.each do |raw, msg|
        callbacks << on(raw) do |env|
          condition.signal(msg)
          callbacks.each { |cb| cb.remove_and_terminate if cb.alive? }
        end
      end

      after(5) do
        condition.signal(:timeout)
        callbacks.each { |cb| cb.remove_and_terminate if cb.alive? }
      end

      raw "NICK :#{nick}"
      Celluloid::Future.new { condition.wait }
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
      channel = Channel.new(channel_name, @actor)
      channel.join(key)
    end

    def message(receiver, message)
      channel = @config.isupport['CHANTYPES'].any? do |chantype|
        receiver.start_with?(chantype)
      end

      if channel
        Channel.new(receiver, @actor).message(message)
      else
        User.new(receiver, @actor).message(message)
      end
    end
  end
end
