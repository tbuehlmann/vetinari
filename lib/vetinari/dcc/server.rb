module Vetinari
  module Dcc
    class Server
      include Celluloid
      attr_reader :user, :filepath

      def initialize(user, filepath, filename, server_manager)
        @user = user
        @filepath = filepath
        @filename = filename
        @server_manager = server_manager
      end

      def run(port)
        @port = port
        internal_ip = @server_manager.internal_ip
        external_ip = @server_manager.external_ip

        cb = @server_manager.bot.on(:query, /\001DCC RESUME \"#{Regexp.escape(@filename)}\" #{@port} \d+\001/, 1) do |env|
        binding.pry
          m = env[:message].match(/\A\001DCC RESUME \"#{Regexp.escape(@filename)}\" #{@port} (\d+)\001\z/)
          @position = (m.captures.first).to_i

          if @position > 0 && @position < File.size(@filepath)
            @user.message("\001DCC ACCEPT \"#{@filename}\" #{@port} #{@position}")
            cb.value.async.remove
          else
            @position = nil
          end
        end

        socket = TCPServer.new(internal_ip, @port)
        @user.message("\001DCC SEND \"#{@filename}\" #{IPAddr.new(external_ip).to_i} #{@port} #{File.size(@filepath)}\001")

        begin
          client = socket.accept

          File.open(@filepath, 'rb') do |file|
            file.seek(@position) if @position

            while buffer = file.read(8096)
              client.write(buffer)
            end
          end

          sleep 1

          client.close
        rescue
          # ...
        end

        socket.close

        cb.value.async.remove
        @server_manager.release_port(@port)
        @server_manager.async.start_sending
      end

      # def resume_at(position)
      #   position = position.to_i
      #   @timeout_timer.cancel
      #   start_timeout_timer
      #   @io.seek(position)
      #   @user.message "\001DCC ACCEPT \"#{@filename}\" #{@port} #{position}\001"
      # end
    end
  end
end
