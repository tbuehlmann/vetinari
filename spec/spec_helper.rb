require 'rspec'
require 'vetinari'
require 'pry'

RSpec.configure do |config|
  config.color_enabled = true
end

Celluloid.logger = nil

module Vetinari
  class Callback
    undef :call

    def call(env)
      @proc.call(env) if matching?(env)
    end
  end
end
