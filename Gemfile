source "http://rubygems.org"

gemspec

if ENV["edge"]
  gem "activerecord", :github => "rails/rails"
  gem "active_record_deprecated_finders", :github => "rails/active_record_deprecated_finders"
end

group :development do
  gem "yard"
  gem "redcarpet"

  platforms :ruby do
    gem "sqlite3"
  end

  platforms :jruby do
    gem "jdbc-sqlite3"
    gem "activerecord-jdbc-adapter"
    gem "jruby-openssl", :require => false # Silence openssl warnings.
  end
end
