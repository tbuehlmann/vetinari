require 'spec_helper'

describe 'Channel Management' do
  subject { Vetinari::Bot.new { |c| c.verbose = false } }

  before(:each) do
    subject.parse(':server 001 Vetinari :Welcome message')
    subject.parse(':server 376 Vetinari :End of /MOTD command.')
  end

  it 'adds a channel to the channel_list when joining a channel' do
    expect(subject.channels.channels).to be_empty
    subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
    expect(subject.channels.channels).to have(1).channel
    expect(subject.channels.channels.first.name).to eq('#mended_drum')
  end

  it 'removes a channel from the channel_list when leaving a channel' do
    subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
    expect(subject.channels.channels).to have(1).channel
    subject.parse(':Vetinari!foo@bar PART #mended_drum')
    expect(subject.channels.channels).to be_empty
  end

  it 'removes a channel from the channel_list when being kicked from a channel' do
    subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
    expect(subject.channels.channels).to have(1).channel
    subject.parse(':TheLibrarian!foo@bar KICK #mended_drum Vetinari :No humans allowed!')
    expect(subject.channels.channels).to be_empty
  end

  it 'removes all channels from the channel_list when quitting' do
    subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
    subject.parse(':Vetinari!foo@bar JOIN #library')
    expect(subject.channels.channels).to have(2).channels
    subject.parse(':Vetinari!foo@bar QUIT :Bye mates!')
    expect(subject.channels.channels).to be_empty
  end
end
