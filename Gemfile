source "https://rubygems.org", cooldown: 3

gemspec

if ENV["edge"]
  gem "activerecord", :github => "rails/rails"
end


group :development, :test do
  gem 'minitest', '~> 5.20'
end

group :development do
  gem 'mocha'
  gem "rake"
  gem "yard"

  platforms :ruby do
    gem "activerecord", "~> 7.0"
    gem "activesupport", "~> 7.0"
    gem "sqlite3", "~> 1.4"
    gem "redcarpet"
    gem "test-unit"
  end

  platforms :jruby do
    gem "activerecord-jdbcsqlite3-adapter"
    gem "jruby-openssl", :require => false # Silence openssl warnings.
  end
end