# frozen_string_literal: true

require "rubygems"
require "rspec"

$LOAD_PATH << "lib"
require "git_commander"

Dir[File.expand_path("../support/**/*.rb", __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = %i[should expect]
  end

  config.mock_with :rspec do |c|
    c.syntax = %i[should expect]
  end
end
