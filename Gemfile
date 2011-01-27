source "http://rubygems.org"

gem "rails-erd", :path => "."
gem "activerecord"
gem "activesupport"
gem "rake"
gem "jeweler"

platforms :ruby do
  gem "sqlite3"
end

platforms :jruby do
  gem "jdbc-sqlite3"
  gem "activerecord-jdbc-adapter"
  gem "jruby-openssl", :require => false # Silence openssl warnings.
end
