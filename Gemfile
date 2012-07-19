source "http://rubygems.org"

gemspec

gem "activerecord", github: "rails/rails"
gem "active_record_deprecated_finders", github: "rails/active_record_deprecated_finders"

group :development do
  platforms :ruby do
    gem "sqlite3"
  end

  platforms :jruby do
    gem "jdbc-sqlite3"
    gem "activerecord-jdbc-adapter"
    gem "jruby-openssl", :require => false # Silence openssl warnings.
  end
end
