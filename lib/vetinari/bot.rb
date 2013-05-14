module Vetinari
  class Bot
    include Celluloid::IO, IRC

    attr_reader :config, :users, :user, :channels, :server_manager, :callbacks

    def initialize(&block)
      @actor     = Actor.current
      @config    = Configuration.new(&block)
      @callbacks = CallbackContainer.new(Actor.current)
      @users     = UserContainer.new
      @channels  = ChannelContainer.new
      @socket    = nil
      @connected = false
      @user      = nil

      setup_channel_and_user_tracking
      setup_default_callbacks
      setup_dcc
    end

    def on(event, options = {}, &block)
      @callbacks.add(event, options, block)
    end

    exclusive :on
    execute_block_on_receiver :on

    def connect
      @config.loggers.info '-- Starting Vetinari'
      @socket = TCPSocket.open(@config.server, @config.port)
      # port, ip = Socket.unpack_sockaddr_in(@socket.to_io.getpeername)
      # @config.internal_port = port
      # @config.internal_ip   = ip
      register

      while message = @socket.gets do
        parse message
      end

      disconnected
    end

    def raw(message, logging = true)
      if @socket
        @socket.puts("#{message}\r\n")
        @config.loggers.info ">> #{message}" if logging
        message
      end
    end

    def connected?
      @connected ? true : false
    end

    def inspect
      nick = @user.nick rescue @config.nick
      "#<Bot nick=#{nick}>"
    end

    def parse(message)
      message.chomp!

      if message =~ /^PING \S+$/
        if @config.hide_ping_pongs
          raw message.sub(/PING/, 'PONG'), false
        else
          @config.loggers.info "<< #{message}"
          raw message.sub(/PING/, 'PONG')
        end
      else
        @config.loggers.info "<< #{message}"
        env = MessageParser.parse(message, @config.isupport['CHANTYPES'])
        @callbacks.call(env)
      end
    end

    private

    def disconnected
      @connected = false
      @config.loggers.info '-- Vetinari disconnected'

      unless @quitted
        if @config.reconnect
          @quitted = nil
          puts "-- Reconnecting in #{@config.reconnect_interval} seconds."
          after(@config.reconnect_interval) { connect }
        end
      end
    end

    def setup_dcc
      if @config.dcc.external_ip && @config.dcc.ports.any?
        @server_manager = Dcc::ServerManager.new(Actor.current)
      end
    end

    def setup_default_callbacks
      [376, 422].each do |raw_numeric|
        on raw_numeric do |env|
          unless @connected
            @connected = true
            @callbacks.call({:type => :connect})
          end
        end
      end

      on 005 do |env|
        @config.isupport.parse(env[:params])
      end

      # User ping request.
      on :query, :pattern => /^\001PING \d+\001$/ do |env|
        time = env[:message].scan(/\d+/)[0]
        env[:user].notice("\001PING #{time}\001")
      end

      on :query, :pattern => /^\001VERSION\001$/ do |env|
        env[:user].notice("\001VERSION Vetinari #{Vetinari::VERSION} (https://github.com/tbuehlmann/vetinari)")
      end

      on :query, :pattern => /^\001TIME\001$/ do |env|
        env[:user].notice("\001TIME #{Time.now.strftime('%a %b %d %H:%M:%S %Y')}\001")
      end
    end

    def setup_channel_and_user_tracking
      # Add the bot user to the user container when connected.
      on 001 do |env|
        nick = env[:params].split(/ /).first
        @user = User.new(nick, @actor) # TODO
        @users.add(@user)
      end

      on :join do |env|
        joined_user = {
          :nick => env.delete(:nick),
          :user => env.delete(:user),
          :host => env.delete(:host)
        }
        channel = env.delete(:channel)

        # TODO: Update existing users with user/host information.

        user = @users[joined_user[:nick]]

        if user
          if user.bot?
            channel = Channel.new(channel, @actor)
            channel.get_mode
            @channels.add(channel)
          else
            channel = @channels[channel]
          end
        else
          channel = @channels[channel]
          user = User.new(joined_user[:nick], self)
          @users.add(user)
        end

        channel.add_user(user, [])
        env[:channel] = channel
        env[:user] = user
      end

      on 353 do |env|
        channel_name = env[:params].split(/ /)[2]
        channel = @channels[channel_name]
        nicks_with_prefixes = env[:params].scan(/:(.*)/)[0][0].split(/ /)
        nicks, prefixes = [], []
        channel_prefixes = @config.isupport['PREFIX'].values.map do |p|
          Regexp.escape(p)
        end.join('|')

        nicks_with_prefixes.each do |nick_with_prefixes|
          nick = nick_with_prefixes.gsub(/#{channel_prefixes}/, '')
          prefixes = nick_with_prefixes.scan(/#{channel_prefixes}/)
          
          unless user = @users[nick]
            user = User.new(nick, @actor)
            @users.add(user)
          end

          channel.add_user(user, prefixes)
        end
      end

      on :part do |env|
        nick    = env.delete(:nick)
        user    = env.delete(:user)
        host    = env.delete(:host)

        # TODO: Update existing users with user/host information.

        user = @users[nick]
        channel = @channels[env.delete(:channel)]

        if user.bot?
          # Remove the channel from the channel_list.
          @channels.remove(channel)

          # Remove all users from the user_list that do not share channels
          # with the Thaum.
          all_known_users = @channels.channels.flat_map(&:users)
          @users.kill_zombie_users(all_known_users)
        else
          channel.remove_user(user)
          remove_user = @channels.channels.none? do |_channel|
            _channel.has_user?(user)
          end

          @users.remove(user) if remove_user
        end

        env[:channel] = channel
        env[:user] = user
      end

      on :kick do |env|
        nick = env.delete(:nick)
        user = env.delete(:user)
        host = env.delete(:host)

        # TODO: Update existing users with user/host information.

        channel = @channels[env.delete(:channel)]
        kicker = @users[nick]
        kickee = @users[env.delete(:kickee)]

        channel.remove_user(kickee)

        if kickee.bot?
          # Remove the channel from the channel_list.
          @channels.remove(channel)

          # Remove all users from the user_list that do not share channels
          # with the Thaum.
          all_known_users = @channels.channels.map(&:users).flatten
          @users.kill_zombie_users(all_known_users)
        else
          remove_user = @channels.channels.none? do |_channel|
            _channel.has_user?(kickee)
          end

          @users.remove(kickee) if remove_user
        end

        env[:kicker]  = kicker
        env[:kickee]  = kickee
        env[:channel] = channel
      end

      # If @config.rejoin_after_kick is set to `true`, let
      # the Thaum rejoin a channel after being kicked.
      on :kick do |env|
        if @config.rejoin_after_kick && env[:kickee].bot?
          key = env[:channel].modes['k']
          env[:channel].join(key)
        end
      end

      on :quit do |env|
        nick = env.delete(:nick)
        user = env.delete(:user)
        host = env.delete(:host)

        # TODO: Update existing users with user/host information.

        user = @users[nick]

        if user.bot?
          channels = @channels.clear
          @users.clear
        else
          channels = @channels.remove_user(user)
          @users.remove(user)
        end

        env[:user] = user
        env[:channels] = channels
      end

      on :disconnect do
        @channels.clear
        @users.clear
      end

      on :channel do |env|
        nick    = env[:nick]
        user    = env[:user]
        host    = env[:host]

        # TODO: Update existing users with user/host information.

        env[:channel] = @channels[env[:channel]]
        env[:user] = @users[nick]
      end

      on :query do |env|
        nick    = env[:nick]
        user    = env[:user]
        host    = env[:host]
        # TODO: Update existing users with user/host information.

        env[:user] = @users[nick] || User.new(nick, @actor)
      end

      on :query, :pattern => /\A\001DCC SEND \"?\S+\"? \d+ \d+ \d+\001\z/ do |env|
        results = env[:message].scan(/\A\001DCC SEND \"?(\S+)\"? (\d+) (\d+) (\d+)\001\z/)
        filename, ip, port, filesize = results.first
        filename = filename.delete("/\\")
        ip       = IPAddr.new(ip.to_i, Socket::AF_INET)
        port     = Integer(port)
        filesize = Integer(filesize)
        file     = Dcc::Incoming::File.new(env[:user], filename, ip, port, filesize, @actor)
        @callbacks.call(env.merge(:type => :dcc, :file => file))
      end

      on :channel_mode do |env|
        # TODO: Update existing users with user/host information.
        # nick = env[:nick]
        # user = env[:user]
        # host = env[:host]

        nick    = env.delete(:nick)
        params  = env.delete(:params)
        modes   = env.delete(:modes)

        channel = @channels[env.delete(:channel)]
        env[:channel] = channel
        env[:user]    = @users[nick]
        env[:channel_modes] = ModeParser.parse(modes, params, @config.isupport)

        env[:channel_modes].each do |mode|
          channel.set_mode(mode, @config.isupport)
        end
      end

      on :nick_change do |env|
        # TODO: Update existing users with user/host information.
        env.delete(:user)
        env.delete(:host)
        env[:old_nick] = env.delete(:nick)
        env[:user] = @users[env[:old_nick]]
        env[:user].renamed_to(env.delete(:new_nick))
      end

      # Response to MODE command, giving back the channel modes.
      on 324 do |env|
        split = env[:params].split(/ /)
        channel_name = split[1]
        channel = @channels[channel_name]

        if channel
          modes = split[2]
          params = split[3..-1]
          mode_changes = ModeParser.parse(modes, params, @config.isupport)

          mode_changes.each do |mode_change|
            channel.set_mode(mode_change, @config.isupport)
          end
        end
      end
    end
  end
end
