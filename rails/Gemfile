source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.1.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.0'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# For memcached
gem 'dalli'

# Added manually to fix error running tests...?
gem 'rexml'

# Use devise for user management and authentication
gem 'devise'

# For captcha and strong passwords
gem 'devise-security'

# Pagination
gem 'will_paginate'

# https://github.com/mbleigh/acts-as-taggable-on
gem 'acts-as-taggable-on', '~> 7.0'

# Why not...
gem 'haml-rails'

# Support S3 for ActiveStorage
gem "aws-sdk-s3", require: false

# For nice emails
gem 'bootstrap-email'

# For thumbnails and screenshots
gem 'grover'

# For payments
gem 'pay', '~> 3.0'
gem 'stripe', '>= 2.8', '< 6.0'

# Needed after ruby 3.1 upgrade
gem 'net-smtp', require: false
gem 'net-pop', require: false
gem 'net-imap', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'

  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  ## It injects javascript so it's not good for TiddlyWikis
  ## TODO: Figure out how to disable it for the tiddlywiki_controller only.
  #gem 'rack-mini-profiler', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  #gem 'spring'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
