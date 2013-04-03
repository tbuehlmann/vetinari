require 'spec_helper'

describe 'Default Callbacks' do
  before(:each) do
    @bot = Vetinari::Bot.new
    @output = []

    def @bot.raw(message, logging)
      @output << message
    end
  end

  it 'PING PONGs' do
    time = Time.now.to_i
    @bot.parse("PING #{time}")
    sleep 1
    expect(@output).to have(1).element#include("PONG #{time}")
  end
end
