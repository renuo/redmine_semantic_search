source "https://rubygems.org"

gem "concurrent-ruby", "1.3.4" # See https://www.redmine.org/issues/42113#note-2
gem "neighbor"
gem "ruby-openai"

group :test do
  gem "rails-controller-testing"
  gem "simplecov", "~> 0.22.0"
end

group :development, :test do
  gem "dotenv-rails"
  gem "rubocop", "~> 1.57", require: false
  gem "rubocop-performance", "~> 1.19", require: false
  gem "rubocop-rails", "~> 2.22", require: false
end
