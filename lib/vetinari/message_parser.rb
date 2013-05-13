module Vetinari
  module MessageParser
    def parse(message, chantypes)
      chantypes = chantypes.map { |c| Regexp.escape(c) }.join('|')

      case message
        # :kornbluth.freenode.net 001 Vetinari5824 :Welcome to the freenode Internet Relay Chat Network Vetinari5824
      when /^(?:\:\S+ )?(\d\d\d) /
        number = $1.to_i
        {:type => number, :params => $'}
      when /^:(\S+)!(\S+)@(\S+) PRIVMSG ((?:#{chantypes})\S+) :/
        {:type => :channel, :nick => $1, :user => $2, :host => $3, :channel => $4, :message => $'}
      when /^:(\S+)!(\S+)@(\S+) PRIVMSG \S+ :/
        {:type => :query, :nick => $1, :user => $2, :host => $3, :message => $'}
      when /^:(\S+)!(\S+)@(\S+) JOIN :*(\S+)$/
        {:type => :join, :nick => $1, :user => $2, :host => $3, :channel => $4}
      when /^:(\S+)!(\S+)@(\S+) PART (\S+)/
        {:type => :part, :nick => $1, :user => $2, :host => $3, :channel => $4, :message => $'.sub(/ :/, '')}
      when /^:(\S+)!(\S+)@(\S+) QUIT/
        {:type => :quit, :nick => $1, :user => $2, :host => $3, :message => $'.sub(/ :/, '')}
      when /^:(\S+)!(\S+)@(\S+) MODE ((?:#{chantypes})\S+) ([+-]\S+)/
        {:type => :channel_mode, :nick => $1, :user => $2, :host => $3, :channel => $4, :modes => $5, :params => $'.lstrip}
      when /^:(\S+)!(\S+)@(\S+) NICK :/
        {:type => :nick_change, :nick => $1, :user => $2, :host => $3, :new_nick => $'}
      when /^:(\S+)!(\S+)@(\S+) KICK (\S+) (\S+) :/
        {:type => :kick, :nick => $1, :user => $2, :host => $3, :channel => $4, :kickee => $5, :message => $'}
      when /^:(\S+)!(\S+)@(\S+) TOPIC (\S+) :/
        {:type => :topic, :nick => $1, :user => $2, :host => $3, :channel => $4, :topic => $'}
      else
        {}
      end
    end
    module_function :parse
  end
end
