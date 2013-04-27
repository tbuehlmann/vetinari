require 'rspec'
require 'vetinari'
require 'pry'

RSpec.configure do |config|
  config.color_enabled = true
end

Celluloid.logger = nil
