require 'rspec'

RSpec.configure do |config|
  config.after(:suite) do
    # Rollback the server
    puts "Roll back test server"
    `cd spec/vagrant/ ; BUNDLE_GEMFILE=../../Gemfile bundle exec vagrant sandbox rollback`
  end
end