source "http://rubygems.org"

gemspec :path => ".."

gem "activerecord", "~> 5.2.8"

group :development do
  gem 'mocha'
  gem "rake"
  gem "yard"

  platforms :ruby do
    gem "sqlite3", '~> 1.3.13'
    gem "redcarpet"
  end

  platforms :jruby do
    gem "activerecord-jdbcsqlite3-adapter"
    gem "jruby-openssl", :require => false # Silence openssl warnings.
  end
end
