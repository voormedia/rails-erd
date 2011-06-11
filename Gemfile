source "http://rubygems.org"

gemspec

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
