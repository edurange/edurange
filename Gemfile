source 'https://rubygems.org'
ruby '2.5.1'
gem 'rails', '~> 5.2.3'
gem 'sass-rails'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'sdoc', '~> 0.4.0',          group: :doc
gem 'bootstrap', '~> 4.3.1'
gem 'devise', '~> 4.6'
gem 'figaro', git: 'https://github.com/laserlemon/figaro'
gem 'haml-rails'
gem 'simple_form'
gem 'underscore-rails'
gem 'thin'
gem 'jquery-turbolinks'
gem 'mini_racer'
gem 'sprockets-rails', :require => 'sprockets/railtie'
# Both versions of the aws-sdk can be used simultaneously.
# We should migrate to the latest version.
# Version 1 of aws-sdk
gem 'aws-sdk-v1', '~> 1.67'
# Version 3 of aws-sdk
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-ec2', '~> 1'

gem 'erubis'
gem 'unix-crypt'
gem 'ipaddress'
gem 'pg'
gem 'rails_12factor'
gem 'netaddr', '~>1.5.1'
gem 'groupdate'
gem 'active_median'
gem 'rubyzip'
gem 'dotenv-rails', :groups => [:development, :test]
gem 'fullcalendar-rails'
gem 'momentjs-rails'
gem 'sidekiq'
gem 'pagy'
gem 'redcarpet'
gem 'font-awesome-rails'

group :development do
  gem 'binding_of_caller', :platforms=>[:mri_20]
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'html2haml'
  gem 'rails_apps_pages'
  gem 'rails_apps_testing'
  gem 'rails_layout'
  gem 'rb-fchange', :require=>false
  gem 'rb-fsevent', :require=>false
  gem 'rb-inotify', :require=>false
  gem 'spring'
end
group :development, :test do
  # gem 'pry-stack_explorer'
  gem 'awesome_print'
  gem 'pry-rails'
  gem 'pry-byebug'
  # gem 'pry-rescue'
  gem 'rspec-rails'
  gem 'daemons'
  gem 'faker'
  gem 'factory_girl_rails', '~> 4.0'
  gem 'sqlite3'
end
group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'selenium-webdriver'
  gem 'rails-controller-testing'
  # gem 'launchy'
  # gem 'plymouth'
  # gem 'pry'
end
