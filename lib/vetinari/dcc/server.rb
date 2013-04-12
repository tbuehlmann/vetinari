module Vetinari
  module Dcc
    class Server
      include Celluloid

      attr_reader :user, :filepath, :state

      def initialize(user, filepath, filename, server_manager)
        @user = user
        @filepath = filepath
        @filename = filename
        @server_manager = server_manager
        @state = :idling
      end

      def run(port)
        @port = port
        register_resume_callback
        start
      end

      def inspect
        "#<Server @user=#{@user.inspect} @filepath=#{filepath}"
      end

      private

      def start
        @thread = Thread.new do
          begin
            int_ip = IPAddr.new(@server_manager.external_ip).to_i
            @socket = TCPServer.new(@server_manager.internal_ip, @port)
            @state = :running
            @user.message("\001DCC SEND \"#{@filename}\" #{int_ip} #{@port} #{File.size(@filepath)}\001")
            @client = @socket.accept
            @state = :sending

            File.open(@filepath, 'rb') do |file|
              file.seek(@position) if @position

              while buffer = file.read(8096)
                @client.write(buffer)
              end
            end

            # Clients like mIRC want to close the connection
            # client side. Else the transfer will count as
            # failed. So, give the client a second to close.
            sleep 1
          rescue StandardError => e
            p e.message
          ensure
            # binding.pry
            async.stop
          end
        end

        after(5) do
          p 'TIMMERERRRRRRRRRRRRRRRRRRRRR'
          if @state == :running
            async.stop(:timeout)
            p :async_stop
          end
        end
      end

      def stop(state = :stopped)
        p 'SERVER STOPPED'
        @state = state
        @client.close rescue nil
        @socket.close rescue nil
        remove_resume_callback
        start_next
      end

      def start_next
        @server_manager.release_port(@port)
        p 'release port'
        @server_manager.async.start_sending
        p 'start sending'
      end

      def register_resume_callback
        @resume_callback = @server_manager.bot.on(:query, /\A\001DCC RESUME \"#{Regexp.escape(@filename)}\" #{@port} \d+\001\z/, 1) do |env|
          if @state == :running
            position = begin
              result = env[:message].scan(/\A\001DCC RESUME \"#{Regexp.escape(@filename)}\" #{@port} (\d+)\001\z/)
              Integer(result.first.first)
            rescue
              0
            end
          
            if position > 0 && position < File.size(@filepath)
              @position = position
              @user.message("\001DCC ACCEPT \"#{@filename}\" #{@port} #{@position}")
              remove_resume_callback
            end
          end
        end
      end

      def remove_resume_callback
        @resume_callback.async.remove
      end
    end
  end
end
