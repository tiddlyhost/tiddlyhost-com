ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"

require 'capybara/rails'
require 'capybara/minitest'
require 'minitest/mock'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
end

class ActionDispatch::IntegrationTest
  # Particularly for sign_in and sign_out methods
  include Devise::Test::IntegrationHelpers

  setup do
    host! Settings.url_defaults[:host]
  end

  def mock_helper
    mock = Minitest::Mock.new
    yield mock if block_given?
    mock
  end

end

class CapybaraIntegrationTest < ActionDispatch::IntegrationTest
  # Make the Capybara DSL available
  include Capybara::DSL

  # Make assert_ methods behave like Minitest assertions
  include Capybara::Minitest::Assertions

  # Configure hostname used for requests
  setup do
    Capybara.app_host = ActionDispatch::Http::URL.full_url_for(Settings.url_defaults)
  end

  # Reset sessions and driver between tests
  teardown do
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

end
