ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_config"

module ActiveSupport
  class TestCase
    # Disable parallel testing to avoid fixture conflicts
    # parallelize(workers: :number_of_processors)

    # Don't load fixtures - tests will create their own data
    # fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
