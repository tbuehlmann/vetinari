module Vetinari
  class Configuration < OpenStruct
    def initialize(&block)
      super
      self.server             = 'chat.freenode.org'
      self.port               = 6667
      self.ssl                = false
      self.nick               = "Vetinari#{rand(10_000)}"
      self.username           = 'Vetinari'
      self.real_name          = 'Havelock Vetinari'
      self.verbose            = true
      self.logging            = false
      self.reconnect          = true
      self.reconnect_interval = 10
      self.hide_ping_pongs    = true
      self.rejoin_after_kick  = false

      self.isupport  = ISupport.new
      self.dcc       = OpenStruct.new
      self.dcc.ports = []

      block.call(self) if block_given?
      setup_loggers
    end

    private

    def setup_loggers
      self.console_logger = if self.verbose
        Logging::Logger.new($stdout)
      else
        Logging::NullLogger.new
      end

      self.logger = if self.logging
        if self.logger
          self.logger
        else
          log_path = File.join($0, 'logs', 'log.log')
          log_dir = File.dirname(log_path)
          FileUtils.mkdir_p(log_dir) unless File.exist?(log_dir)
          Logging::Logger.new(log_path, File::WRONLY | File::APPEND)
        end
      else
        Logging::NullLogger.new
      end

      self.loggers = Logging::LoggerList.new
      self.loggers.push(self.console_logger, self.logger)
    end
  end
end
