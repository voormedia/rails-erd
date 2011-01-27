source "http://rubygems.org"

gem "activerecord", "~> 3.0"
gem "activesupport", "~> 3.0"
gem "ruby-graphviz", "~> 0.9.18"

group :development do
  gem "rake"
  gem "bundler", "~> 1.0.0"
  gem "jeweler", "~> 1.5.2"

  platforms :ruby do
    gem "sqlite3"
  end

  platforms :jruby do
    gem "jdbc-sqlite3"
    gem "activerecord-jdbc-adapter"
    gem "jruby-openssl", :require => false # Silence openssl warnings.
  end
end
