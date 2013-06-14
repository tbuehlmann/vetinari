require 'spec_helper'

describe 'Bot#rename' do
  subject { Vetinari::Bot.new { |c| c.verbose = false } }

  before(:each) do
    Celluloid.shutdown
    Celluloid.boot
    subject.parse(':server 001 Vetinari :Welcome message')
    subject.parse(':server 376 Vetinari :End of /MOTD command.')
    subject.parse(':server 005 Vetinari NICKLEN=10')
  end

  it 'returns a Future' do
    expect(subject.rename('Havelock')).to be_a(Celluloid::Future)
  end

  it 'returns the current nickname if no changes would happen' do
    future = subject.rename('Vetinari')
    expect(future.value).to be_a(String)
    expect(future.value).to eq('Vetinari')
  end

  it 'returns String if renamed' do
    future = subject.rename('Havelock')

    Thread.new do
      subject.parse(':Vetinari!foo@bar NICK :Havelock')
    end

    expect(future.value).to be_a(String)
    expect(future.value).to eq('Havelock')
  end

  it 'returns :erroneous_nickname if nickname is erroneous' do
    future = subject.rename('NickServ')

    Thread.new do
      subject.parse(':server 432 Vetinari NickServ :Erroneous Nickname')
    end

    expect(future.value).to be_a(Symbol)
    expect(future.value).to eq(:erroneous_nickname)
  end

it 'returns :nickname_in_use if nickname is taken' do
    future = subject.rename('TheLibrarian')

    Thread.new do
      subject.parse(':server 433 Vetinari TheLibrarian :Nickname is already in use.')
    end

    expect(future.value).to be_a(Symbol)
    expect(future.value).to eq(:nickname_in_use)
  end

  it 'slices the nick if it is too long' do
    bare = subject.bare_object
    expect(bare).to receive(:raw).with('NICK :1234567890').once
    subject.rename('1234567890over')
  end
end
