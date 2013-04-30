module Vetinari
  module Dcc
    module Incoming
      class File
        include Celluloid::IO, Celluloid::Notifications

        attr_reader :user, :filename, :ip, :port
        attr_reader :filesize, :state

        def initialize(user, filename, ip, port, filesize, bot)
          @user       = user
          @filename   = filename
          @ip         = ip
          @port       = port
          @filesize   = filesize
          @bot        = bot
          @mutex      = Mutex.new
          
          self.state = :pending
        end

        def accept(directory = '~/Downloads/', resume = false)
          if @state == :pending
            self.state = :accepted
            directory = ::File.expand_path(directory)
            @filepath = ::File.join(directory, @filename)

            if resume && resumable?
              resume_transfer
            else
              download
            end
          end
        end

        def inspect
          "#<File filename=#{@filename} filesize=#{@filesize} user=#{@user.inspect}"
        end

        def resume_accepted(position)
          self.state = :resume_accepted
          download(position)
        end

        def state=(state)
          old_state = @state
          @state = state
          publish('vetinari.dcc.incoming.file', Actor.current, old_state, @state)
        end

        private

        def download(position = 0)
          self.state = :connecting

          begin
            @socket = TCPSocket.new(@ip.to_s, @port)
            self.state = :connected
          rescue Errno::ECONNREFUSED
            self.state = :failed
            return
          end

          file_mode = position > 0 ? 'a' : 'w'

          begin
            ::File.open(@filepath, file_mode) do |file|
              self.state = :downloading

              while buffer = @socket.readpartial(8192)
                position += buffer.bytesize
                file.write(buffer)
                break if position >= @filesize
              end
            end

            self.state = :finished
          rescue EOFError
            self.state = :aborted
          ensure
            @socket.close
          end
        ensure
          return self
        end

        def resumable?
          ::File.file?(@filepath) && ::File.size(@filepath) <= @filesize
        end

        def resume_transfer
          self.state = :resuming
          filename = Regexp.escape(@filename)
          position = ::File.size(@filepath)
          file = Actor.current

          cb = @bot.on(:query, /\A\001DCC ACCEPT \"?#{filename}\"? #{@port} #{position}\001\z/, 1) do |env|
            file.async.resume_accepted(position)
            cb.async.remove
          end

          @user.message("\001DCC RESUME \"#{@filename}\" #{@port} #{position}\001")

          after(30) do
            if @state == :resuming
              cb.remove
              file.state = :resume_not_accepted
            end
          end
        end
      end
    end
  end
end
