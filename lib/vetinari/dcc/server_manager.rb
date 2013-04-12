module Vetinari
  module Dcc
    class ServerManager
      include Celluloid

      attr_reader :bot, :internal_ip, :external_ip

      def initialize(bot)
        @bot = bot
        @external_ip = @bot.config.dcc.external_ip

        ip = Socket.ip_address_list.detect { |i| i.ipv4_private? }
        @internal_ip = ip ? ip.ip_address : '0.0.0.0'

        @ports = @bot.config.dcc.ports
        @queue = []
        @mutex = Mutex.new
        @running_servers = {} # {port => #<Vetinari::Dcc::Server>}
      end

      def add_offering(user, filepath, filename)
        server = Server.new(user, filepath, filename, Actor.current)
        @mutex.synchronize { @queue << server }
        async.start_sending
        server
      end

      def start_sending
        @mutex.synchronize do
          if @queue.any?
            port = get_available_port

            if port
              server = @queue.pop
              server.async.run(port)
              @running_servers[port] = server
            else
              # There are items in the queue but for some reasons no ports are
              # available. Try again later.
              after(3) { start_sending }
            end
          end
        end
      end

      def release_port(port)
        @mutex.synchronize do
          @running_servers.delete(port)
        end
      end

      # def find_server(user, filename, port)
      #   server = @running_servers[port]

      #   if server && server.user == user && server.filename == filename
      #   end
      # end

      private

      def get_available_port
        (@ports - @running_servers.keys).shuffle.each do |port|
          return port if port_available?(port)
        end

        nil
      end

      def port_available?(port)
        Timeout::timeout(3) do
          begin
            TCPServer.new(port).close
            true
          rescue Errno::EADDRINUSE
            false
          end
        end
      rescue Timeout::Error
        false
      end
    end
  end
end
