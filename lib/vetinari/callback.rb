module Vetinari
  class Callback
    include Celluloid

    attr_reader :event
    attr_writer :container
    finalizer :finalize

    def initialize(event, pattern, proc, container)
      @event = event
      @pattern = pattern
      @container = container
      @proc = proc
    end

    def call(env)
      begin
        @proc.call(env) if matching?(env)
      rescue => e
        loggers = @container.bot.config.loggers
        loggers.error "-- #{e.class}: #{e.message}"
        e.backtrace.each { |line| loggers.error("-- #{line}") }
      end
    end

    def remove
      # TODO: Works just for worker=1?
      @container.remove(Actor.current)
      Actor.current.terminate if Actor.current.alive?
    end

    def inspect
      "#<Callback event=#{@event.inspect}>" # TODO
    end

    def finalize
      remove
    end

    private

    def matching?(env)
      case @event
      when :channel, :query
        env[:message] =~ @pattern
      else
        true
      end
      # TODO
    end
  end
end
