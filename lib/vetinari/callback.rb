module Vetinari
  class Callback
    include Celluloid

    attr_reader :event
    attr_writer :container

    def initialize(event, options, proc, container, uuid)
      @event = event
      @options = options
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

    def remove_and_terminate
      @container.remove(@event, @uuid, true)
    end

    def inspect
      event   = @event.inspect
      options = @options.inspect
      uuid    = @uuid.inspect
      "#<Callback event=#{event} options=#{options} uuid=#{uuid}>"
    end

    private

    def matching?(env)
      case @event
      when :channel, :query
        if @options[:pattern]
          env[:message] =~ @options[:pattern] ? true : false
        else
          true
        end
      else
        true
      end
    end
  end
end
