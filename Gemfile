# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.4.1"

gem "bootsnap", ">= 1.1.0", require: false
gem "jsonapi-resources"
gem "puma", "~> 3.11"
gem "rails", "~> 5.2.0"
gem "sqlite3"

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "rspec"
  gem "rspec-rails"
  gem "rubocop", ">= 0.57.2", require: false
end

group :development do
  gem "brakeman"
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
