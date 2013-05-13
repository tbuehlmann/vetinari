require 'spec_helper'

describe Vetinari::User do
  bot = Vetinari::Bot.new
  subject { Vetinari::User.new('Ridcully', bot) }

  it 'responds to #to_s' do
    expect(subject.to_s).to eq('Ridcully')
  end
end
