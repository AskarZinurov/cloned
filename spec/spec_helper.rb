require 'bundler/setup'
require 'yaml'
require 'active_record'
require 'sqlite3'
require 'cloned'

current_dir = File.dirname(__FILE__)
config = YAML.safe_load(IO.read(current_dir + '/database.yml'))

ActiveRecord::Base.logger = ActiveSupport::Logger.new(current_dir + '/debug.log')
ActiveRecord::Base.establish_connection(config['sqlite3'])
load(current_dir + '/schema.rb')

require 'models'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
