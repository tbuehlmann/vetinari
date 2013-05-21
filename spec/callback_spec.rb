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

  it 'can be removed and terminated' do
    cb = subject.on(:channel)
    expect(callbacks[:channel]).to have(2).callback
    expect(cb.alive?).to be_true
    cb.remove_and_terminate
    expect(callbacks[:channel]).to have(1).callback
    expect(cb.alive?).to be_false
  end
end
