require 'spec_helper'

describe Vetinari::Channel do
  bot = Vetinari::Bot.new
  subject { Vetinari::Channel.new('#mended_drum', bot) }

  it 'responds to #to_s' do
    expect(subject.to_s).to eq('#mended_drum')
  end
end
