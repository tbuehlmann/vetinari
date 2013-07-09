require 'spec_helper'

describe Vetinari::Bot.new do
  subject { Vetinari::Bot.new { |c| c.verbose = false } }
  before(:each) do
    Celluloid.shutdown
    Celluloid.boot
  end

  it 'terminates all linked actors on termination' do
    expect do
      subject.parse(':server 001 Vetinari :Welcome message')
      subject.parse(':server 376 Vetinari :End of /MOTD command.')
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':TheLibrarian!foo@bar JOIN #mended_drum')
      subject.terminate
    end.to_not change { Celluloid::Actor.all.size }
  end

  it 'terminates all linked actors on termination with wild channels' do
    expect do
      subject.parse(':server 001 Vetinari :Welcome message')
      subject.parse(':server 376 Vetinari :End of /MOTD command.')
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':TheLibrarian!foo@bar JOIN #mended_drum')
      Vetinari::Channel.new('#unseen_university', subject)
      subject.terminate
    end.to_not change { Celluloid::Actor.all.size }
  end

  it 'should not die if a linked channel dies' do
    channel = Vetinari::Channel.new('#mended_drum', subject)

    def (channel.bare_object).crash
      raise 'boom'
    end

    expect(subject.links).to include(channel)
    channel.crash rescue nil
    expect(channel).to_not be_alive
    expect(subject).to be_alive
  end
end
