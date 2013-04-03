module Vetinari
  module Logging
    class NullLogger
      %w(debug info warn error fatal unknown method_missing).each do |method_name|
        define_method(method_name) { |*args, &block| }
      end
    end
  end
end
