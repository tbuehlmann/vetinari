require 'spec_helper'

describe 'User Management' do
  subject { Vetinari::Bot.new { |c| c.verbose = false } }
  before(:each) do
    Celluloid.shutdown
    Celluloid.boot
  end

  context 'Connecting to the server' do
    it 'adds itself to the user_list when connected to the server' do
      expect(subject.users.users).to be_empty
      subject.parse(":server 001 Vetinari :Welcome message")
      subject.parse(':server 376 Vetinari :End of /MOTD command.')
      expect(subject.users.users).to have(1).user
      expect(subject.users.users.first).to be(subject.user)
    end
  end

  context 'Connected to the server' do
    before(:each) do
      subject.parse(":server 001 Vetinari :Welcome message")
      subject.parse(":server 376 Vetinari :End of /MOTD command.")
    end

    it 'adds an user to the user_list when the user joins a channel the Thaum is in' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      expect(subject.users.users).to have(1).user
      subject.parse(':TheLibrarian!foo@bar JOIN #mended_drum')
      expect(subject.users.users).to have(2).users
    end

    it 'adds an user to the channel when the user joins a channel the Thaum is in' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      channel = subject.channels['#mended_drum']
      expect(channel.users).to have(1).user
      subject.parse(':TheLibrarian!foo@bar JOIN #mended_drum')
      expect(channel.users).to have(2).users
    end

    it 'adds user to the user_list when the Thaum joins a channel with users in it' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      expect(subject.users.users).to have(1).user
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian +Ridcully')
      expect(subject.users.users).to have(3).users
    end

    it 'adds user to the user_list when the Thaum joins a channel with users in it without doublets' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian +Ridcully')
      subject.parse(':Vetinari!foo@bar JOIN #library')
      subject.parse(':server 353 Vetinari @ #library :Vetinari TheLibrarian')
      expect(subject.users.users).to have(3).users
    end

    it 'adds user to a channel when the Thaum joins a channel with users in it' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      channel = subject.channels['#mended_drum']
      expect(channel.users).to have(1).user
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian +Ridcully')
      expect(channel.users).to have(3).users
    end

    it 'removes an user from the user_list when quitting' do
      expect(subject.users.users).to have(1).user
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian +Ridcully')
      expect(subject.users.users).to have(3).users
      subject.parse(':TheLibrarian!foo@bar QUIT :Going to eat a banana.')
      expect(subject.users.users).to have(2).users
    end

    it 'removes an user from all channels when quitting' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian')
      subject.parse(':Vetinari!foo@bar JOIN #library')
      subject.parse(':server 353 Vetinari @ #library :Vetinari +TheLibrarian')
      mended_drum = subject.channels['#mended_drum']
      expect(mended_drum.users).to have(2).users
      library = subject.channels['#library']
      expect(library.users).to have(2).users
      subject.parse(':TheLibrarian!foo@bar QUIT :Going to eat a banana.')
      expect(mended_drum.users).to have(1).users
      expect(library.users).to have(1).users
    end

    it 'removes an user from a channel when the user parts' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian')
      channel = subject.channels['#mended_drum']
      expect(channel.users).to have(2).users
      subject.parse(':TheLibrarian!foo@bar PART #mended_drum')
      expect(channel.users).to have(1).user
    end

    it 'removes an user from a channel when being kicked' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian')
      channel = subject.channels['#mended_drum']
      expect(channel.users).to have(2).users
      subject.parse(':Vetinari!foo@bar KICK #mended_drum TheLibrarian :Go out!')
      expect(channel.users).to have(1).user
    end

    it 'does not remove an user from the user_list when the user parts a channel and the user in another channel the Thaum is in' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian')
      subject.parse(':Vetinari!foo@bar JOIN #library')
      subject.parse(':server 353 Vetinari @ #library :Vetinari @TheLibrarian')
      expect(subject.users.users).to have(2).users
      subject.parse(':TheLibrarian!foo@bar PART #mended_drum')
      expect(subject.users.users).to have(2).users
    end

    it 'removes an user from the users when the user parting the last channel the Thaum is in' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian')
      expect(subject.users.users).to have(2).users
      subject.parse(':TheLibrarian!foo@bar PART #mended_drum')
      expect(subject.users.users).to have(1).user
    end

    it 'removes an user from the user_list when being kicked from the last channel the Thaum is in' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian')
      expect(subject.users.users).to have(2).users
      subject.parse(':Vetinari!foo@bar KICK #mended_drum TheLibrarian :Go out!')
      expect(subject.users.users).to have(1).user
    end

    it 'removes an user from the user_list when parting if the user is no other channel the Thaum is in' do
      subject.parse(':Vetinari!foo@bar JOIN #mended_drum')
      subject.parse(':server 353 Vetinari @ #mended_drum :Vetinari @TheLibrarian')
      expect(subject.users.users).to have(2).users
      subject.parse(':Vetinari!foo@bar PART #mended_drum')
      expect(subject.users.users).to have(1).users
    end
  end
end
