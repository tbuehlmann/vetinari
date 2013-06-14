require 'spec_helper'

describe 'Bot#join' do
  subject { Vetinari::Bot.new { |c| c.verbose = false } }

  before(:each) do
    Celluloid.shutdown
    Celluloid.boot
    subject.parse(':server 001 Vetinari :Welcome message')
    subject.parse(':server 376 Vetinari :End of /MOTD command.')
  end

  it 'returns a Future' do
    expect(subject.join('#mended_drum')).to be_a(Celluloid::Future)
  end

  it 'returns :joined if joined' do
    future = subject.join('#mended_drum')

    Thread.new do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
    end

    expect(future.value).to be(:joined)
  end

  it 'returns :already_joined if already in the channel' do
    subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
    future = subject.join('#mended_drum')
    expect(future.value).to be(:already_joined)
  end

  it 'returns :locked if channel is locked' do
    future = subject.join('#mended_drum')

    Thread.new do
      subject.parse(':server 475 Vetinari #mended_drum :Cannot join channel (+k) - bad key')
    end
    
    expect(future.value).to be(:locked)
  end

  it 'returns :full if channel is full' do
    future = subject.join('#mended_drum')

    Thread.new do
      subject.parse(':server 471 Vetinari #mended_drum :Cannot join channel (+l) - channel is full, try again later')
    end
    
    expect(future.value).to be(:full)
  end

  it 'returns :banned if the bot is banned from the channel' do
    future = subject.join('#mended_drum')

    Thread.new do
      subject.parse(':server 474 Vetinari #mended_drum :Cannot join channel (+b) - you are banned')
    end
    
    expect(future.value).to be(:banned)
  end

  it 'returns :banned if the bot is banned from the channel' do
    future = subject.join('#mended_drum')

    Thread.new do
      subject.parse(':server 473 Vetinari #mended_drum :Cannot join channel (+i) - you must be invited')
    end
    
    expect(future.value).to be(:invite_only)
  end

  it 'returns :timeout if no answer comes from the server' do
    future = subject.join('#mended_drum')
    expect(future.value).to be(:timeout)
  end
end
