require 'spec_helper'

describe 'Callback' do
  subject { Vetinari::Bot.new { |c| c.verbose = false } }
  let(:callbacks) { subject.callbacks.instance_variable_get('@callbacks') }

  it 'is added correctly' do
    expect(callbacks[:channel]).to have(1).callback
    subject.on(:channel)
    expect(callbacks[:channel]).to have(2).callbacks
  end

  it 'can be removed' do
    cb = subject.on(:channel)
    expect(callbacks[:channel]).to have(2).callback
    cb.remove
    expect(callbacks[:channel]).to have(1).callback
  end
end
