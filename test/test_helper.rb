require "rubygems"
require "test/unit"
require "active_support/test_case"

require "rails_erd/domain"

require "active_record"
require "sqlite3"

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

include RailsERD

class ActiveSupport::TestCase
  teardown :reset_domain

  def create_table(table, columns = {}, pk = nil)
    opts = if pk then { :primary_key => pk } else { :id => false } end
    ActiveRecord::Schema.define do
      suppress_messages do
        create_table table, opts do |t|
          columns.each do |column, type|
            t.send type, column
          end
        end
      end
    end
  end
  
  def add_column(*args)
    ActiveRecord::Schema.define do
      suppress_messages do
        add_column *args
      end
    end
  end

  def create_model(name, columns = {}, &block)
    klass = Object.const_set name.to_sym, Class.new(ActiveRecord::Base)
    klass.class_eval(&block) if block_given?
    create_table Object.const_get(name.to_sym).table_name, columns, Object.const_get(name.to_sym).primary_key rescue nil
  end
    
  def create_models(*names)
    names.each do |name|
      create_model name
    end
  end
  
  def collect_stdout
    stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.rewind
    $stdout.read
  ensure
    $stdout = stdout
  end
  
  private
  
  def reset_domain
    ActiveRecord::Base.descendants.each do |model|
      Object.send :remove_const, model.name.to_sym
    end
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table table
    end
    ActiveRecord::Base.direct_descendants.clear
    Arel::Relation.send :class_variable_set, :@@connection_tables_primary_keys, {}
    ActiveSupport::Dependencies::Reference.clear!
  end
end
