require 'ipaddr'
require 'logger'
require 'ostruct'
require 'securerandom'
require 'thread'

require 'celluloid/io'

module Vetinari
  require 'vetinari/irc'
  require 'vetinari/bot'
  require 'vetinari/callback'
  require 'vetinari/callback_container'
  require 'vetinari/channel'
  require 'vetinari/channel_container'
  require 'vetinari/configuration'
  require 'vetinari/isupport'
  require 'vetinari/message_parser'
  require 'vetinari/mode_parser'
  require 'vetinari/user'
  require 'vetinari/user_container'
  require 'vetinari/version'

  module Dcc
    require 'vetinari/dcc/server_manager'
    require 'vetinari/dcc/server'
  end

  module Logging
    require 'vetinari/logging/logger'
    require 'vetinari/logging/logger_list'
    require 'vetinari/logging/null_logger'
  end
end
