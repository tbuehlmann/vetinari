lib_dir = File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift lib_dir

require 'vetinari'

echo_bot = Vetinari::Bot.new do |config|
  config.server = 'chat.freenode.org'
  config.port   = 6667
  config.nick   = "Vetinari#{rand(10_000)}"
end

echo_bot.on :connect do
  echo_bot.join '#vetinari'
end

echo_bot.on :channel, /\Aquit!\z/ do |env|
  echo_bot.quit
end

echo_bot.on :channel, //, 1 do |env|
  env[:channel].message(env[:message])
end

echo_bot.connect
