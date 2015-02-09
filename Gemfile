source "http://rubygems.org"

gemspec

if ENV["edge"]
  gem "activerecord", :github => "rails/rails"
end

group :development do
  gem "rake"
  gem "yard"

  platforms :ruby do
    gem "sqlite3"
    gem "redcarpet"

    if RUBY_VERSION > "2.1.0"
      gem "test-unit" # not bundled in CRuby since 2.2.0
    end
  end

  platforms :jruby do
    gem "activerecord-jdbcsqlite3-adapter"
    gem "jruby-openssl", :require => false # Silence openssl warnings.
  end
end
