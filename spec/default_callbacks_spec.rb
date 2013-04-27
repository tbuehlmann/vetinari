require 'spec_helper'

describe Vetinari::Bot do
  subject { Vetinari::Bot.new { |c| c.verbose = false } }
  let(:bare) { subject.bare_object }

  before(:each) do
    subject.parse(':server 001 Vetinari :Welcome message')
    subject.parse(':server 376 Vetinari :End of /MOTD command.')
  end

  it 'PING PONGs (server)' do
    bare.should_receive(:raw).with("PONG :server", false)
    subject.parse("PING :server")
  end

  it 'PING PONGs (user)' do
    time = Time.now.to_i
    bare.should_receive(:raw).with("NOTICE nick :\001PING #{time}\001")
    subject.parse(":nick!user@host PRIVMSG Vetinari :\001PING #{time}\001")
  end

  it 'responses to VERSION request' do
    bare.should_receive(:raw).with("NOTICE nick :\001VERSION Vetinari #{Vetinari::VERSION} (https://github.com/tbuehlmann/vetinari)")
    subject.parse(":nick!user@host PRIVMSG Vetinari :\001VERSION\001")
  end

  it 'responses to TIME request' do
    bare.should_receive(:raw).with("NOTICE nick :\001TIME #{Time.now.strftime('%a %b %d %H:%M:%S %Y')}\001")
    subject.parse(":nick!user@host PRIVMSG Vetinari :\001TIME\001")
  end
end
