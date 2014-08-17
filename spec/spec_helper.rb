# Coveralls requires Ruby 1.9.2
unless RUBY_VERSION == '1.8.7'
  require 'coveralls'
  Coveralls.wear!
end

require 'headless'