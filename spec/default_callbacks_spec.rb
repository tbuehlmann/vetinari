require 'spec_helper'

describe Vetinari::Bot do
  subject { Vetinari::Bot.new { |c| c.verbose = false } }
  let(:bare) { subject.bare_object }

  before(:each) do
    Celluloid.shutdown
    Celluloid.boot
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

  describe 'rejoin channel after kick' do
    let(:channel) { subject.channels['#mended_drum'] }

    before(:each) do
      subject.config.rejoin_after_kick = true
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':TheLibrarian!foo@bar JOIN #mended_drum')
    end

    it 'without a channel key' do
      channel.should_receive(:join)
      subject.parse(':TheLibrarian!foo@bar KICK #mended_drum Vetinari :foo')
    end

    it 'with a channel key' do
      channel.should_receive(:join).with('thaum')
      subject.parse(':Vetinari!foo@bar MODE #mended_drum +k thaum')
      subject.parse(':TheLibrarian!foo@bar KICK #mended_drum Vetinari :foo')
    end
  end

  describe 'on :nick_change' do
    before(:each) do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':Ridcully!foo@bar JOIN #mended_drum')
    end

    it 'works' do
      user = subject.users['Ridcully']
      subject.parse(':Ridcully!foo@bar NICK :Twoflower')
      expect(user.nick).to eq('Twoflower')
    end

    it 'sets the old nick properly' do
      subject.on :nick_change do |env|
        expect(env[:old_nick]).to eq('Ridcully')
        @called = true
      end

      subject.parse(':Ridcully!foo@bar NICK :Twoflower')
      expect(@called).to be_true
    end
  end
end
