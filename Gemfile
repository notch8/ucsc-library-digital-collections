source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
# Use sqlite3 as the database for Active Record
#gem 'sqlite3'
gem 'mysql2'

# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

#gem 'sufia', '7.3.0'
gem 'hyrax', '2'

group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

gem 'rsolr', '~> 1.0'
gem 'devise'
gem 'devise-guests', '~> 0.5'

group :development, :test do
  gem 'fcrepo_wrapper'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'capybara'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger', '>= 0.1.1'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
end

gem 'hydra-role-management'
gem 'browse-everything'
#gem 'hydra-remote_identifier'

gem 'samvera_hls', path: "/srv/samvera_hls/"
gem 'scooby_snacks', path: "/srv/scooby_snacks/"

#gem 'ldfwrapper', github: 'boston-library/ldf-wrapper', branch: "master"

#gem 'nokogiri'
#gem 'equivalent-xml'

gem 'sinatra', github: 'sinatra'

gem 'resque-pool'
gem 'sidekiq'
gem 'capistrano-sidekiq', github: 'seuros/capistrano-sidekiq'


gem 'blacklight_advanced_search', '~> 6.0'
gem 'blacklight_oai_provider', path: '/srv/blacklight_oai_provider'
gem 'riiif', '~> 1.1'
