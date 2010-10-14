require "rubygems"
require "bundler/setup"

require "active_record"
require "test/unit"
require "rails_erd/domain"

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

class ActiveSupport::TestCase
  include RailsERD

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

  def create_model(name, *args, &block)
    superklass = args.first.kind_of?(Class) ? args.shift : ActiveRecord::Base
    columns = args.first || {}
    klass = Object.const_set name.to_sym, Class.new(superklass)
    klass.class_eval(&block) if block_given?
    if superklass == ActiveRecord::Base
      create_table Object.const_get(name.to_sym).table_name, columns, Object.const_get(name.to_sym).primary_key rescue nil
    end
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
  
  def create_simple_domain
    create_model "Beer", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
  end
  
  def create_one_to_one_assoc_domain
    create_model "One" do
      has_one :other
    end
    create_model "Other", :one => :references do
      belongs_to :one
    end
  end

  def create_one_to_many_assoc_domain
    create_model "One" do
      has_many :many
    end
    create_model "Many", :one => :references do
      belongs_to :one
    end
  end

  def create_many_to_many_assoc_domain
    create_model "Many" do
      has_and_belongs_to_many :more
    end
    create_model "More" do
      has_and_belongs_to_many :many
    end
    create_table "manies_mores", :many_id => :integer, :more_id => :integer
  end
  
  def create_specialization
    create_model "Beverage", :type => :string
    Object.const_set :Beer, Class.new(Beverage)
  end
  
  def create_generalization
    create_model "Cannon"
    create_model "Galleon" do
      has_many :cannons, :as => :defensible
    end
  end

  private
  
  def reset_domain
    if defined? ActiveRecord
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
end
