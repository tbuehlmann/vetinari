module Vetinari
  class CallbackContainer
    include Celluloid

    attr_reader :bot

    def initialize(bot)
      @bot = bot
      @callbacks = Hash.new { |hash, key| hash[key] = {} }
    end
    
    def add(event, pattern, worker, proc)
      args = [event, pattern, proc, Actor.current]
      worker = Integer(worker)

      case
      when worker == 1
        callback = Callback.new(*args)
        synchronicity = :async
      when worker > 1
        callback = Callback.pool(:size => worker, :args => args)
        synchronicity = :async
      else
        callback = Callback.new(*args)
        synchronicity = :sync
      end

      @callbacks[callback.event][callback] = synchronicity
      callback
    end

    def remove(callback)
      if @callbacks.key?(callback.event)
        deleted = @callbacks[callback.event].delete(callback)

        if deleted
          if @callbacks[callback.event].empty?
            @callbacks.delete(callback.event)
          end

          return callback
        end
      end

      nil
    end

    def call(env)
      if @callbacks.key?(env[:type])
        @callbacks[env[:type]].each do |callback, synchronicity|
          case synchronicity
          when :sync
            callback.call(env)
          when :async
            callback.async.call(env)
          end
        end
      end
    end

    def inspect
      "#<CallbackContainer bot=#{@bot.inspect}>"
    end
  end
end
