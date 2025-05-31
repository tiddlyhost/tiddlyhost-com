if ENV['COVERAGE'] == '1'
  require 'simplecov'
  SimpleCov.start
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

require 'capybara/rails'
require 'capybara/minitest'
require 'minitest/mock'

module Warning
  def self.warn(msg)
    # Suppress warning that will (hopefully) soon be fixed by https://github.com/rails/marcel/pull/123
    super unless msg =~ %r{lib/marcel/magic.rb:120: warning: literal string will be frozen in the future}
  end
end

def for_all_empties
  Dir["#{Rails.root}/tw_content/empties/*"].each do |kind_dir|
    Dir["#{kind_dir}/*.html"].each do |empty_file|
      tw_kind = File.basename(kind_dir)

      tw_version = File.basename(empty_file, '.html')
      yield(empty_file, tw_kind, tw_version)
    end
  end
end

module NewSiteHelper
  def new_site_helper(name:, user:, empty: :tw5, tiddlers: {}, empty_content: nil)
    empty = Empty.find_by_name(empty)
    th_file = empty.th_file

    # Instead of the named empty, use the content provided
    th_file = ThFile.new(empty_content) if empty_content

    # Inject tiddlers
    tw_html = th_file.write_tiddlers(tiddlers).to_html

    Site.create!({ name:, empty_id: empty.id, user_id: user.id }.
      merge(WithSavedContent.attachment_params(tw_html)))
  end
end

class ActiveSupport::TestCase
  include NewSiteHelper

  # Run tests in parallel with specified workers
  # (Simplecov doesn't handle parallel workers, so skip when running coverage tests)
  parallelize(workers: :number_of_processors) unless ENV['COVERAGE'] == '1'

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
end

class ActionDispatch::IntegrationTest
  # Particularly for sign_in and sign_out methods
  include Devise::Test::IntegrationHelpers

  include NewSiteHelper

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
