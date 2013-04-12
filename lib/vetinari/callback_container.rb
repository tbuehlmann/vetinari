module Vetinari
  class CallbackContainer
    attr_reader :bot

    def initialize(bot)
      @bot = bot
      @callbacks = Hash.new { |hash, key| hash[key] = {} }
      @mutex = Mutex.new
    end
    
    def add(event, pattern, worker, proc)
      uuid = SecureRandom.uuid
      args = [event, pattern, proc, self, uuid]
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

      @mutex.synchronize do
        @callbacks[callback.event][uuid] = {
          :callback      => callback,
          :synchronicity => synchronicity
        }
      end

      callback
    end

    def remove(event, uuid)
      @mutex.synchronize do
        if @callbacks.key?(event)
          hash = @callbacks[event].delete(uuid)

          if hash
            # https://github.com/celluloid/celluloid/issues/197
            # callback.soft_terminate

            # #terminate is broken for Pools:
            # https://github.com/celluloid/celluloid/pull/207
            #
            # So, don't terminate for now.
            # hash[:callback].terminate
            return true
          end
        end
      end

      false
    end

    def call(env)
      callbacks = nil

      @mutex.synchronize do
        if @callbacks.key?(env[:type])
          callbacks = @callbacks[env[:type]].values.dup
        end
      end

      if callbacks
        callbacks.each do |hash|
          case hash[:synchronicity]
          when :sync
            hash[:callback].call(env)
          when :async
            hash[:callback].async.call(env)
          end
        end
      end
    end

    def inspect
      "#<CallbackContainer bot=#{@bot.inspect}>"
    end
  end
end
