module Vetinari
  class Callback
    include Celluloid

    attr_reader :event
    attr_writer :container

    def initialize(event, pattern, proc, container, uuid)
      @event = event
      @pattern = pattern
      @proc = proc
      @container = container
      @uuid = uuid
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
      @container.remove(@event, @uuid)
    end

    def inspect
      event   = @event.inspect
      pattern = @pattern.inspect
      uuid    = @uuid.inspect
      "#<Callback event=#{event} pattern=#{pattern} uuid=#{uuid}>"
    end

    private

    def matching?(env)
      case @event
      when :channel, :query
        env[:message] =~ @pattern
      else
        true
      end
    end
  end
end
