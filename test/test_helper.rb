require "rubygems"
require "bundler/setup"

require "active_record"

if ActiveSupport::VERSION::MAJOR >= 4
  require "minitest/autorun"
  require 'mocha/mini_test'
else
  require "test/unit"
  require 'mocha/test_unit'
end

require "rails_erd/domain"

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

if ActiveSupport::TestCase.respond_to?(:test_order=)
  ActiveSupport::TestCase.test_order = :random
end

class ActiveSupport::TestCase
  include RailsERD

  setup    :reset_config_file
  teardown :reset_domain

  def create_table(table, columns = {}, pk = nil)
    opts = if pk then { :primary_key => pk } else { :id => false } end
    ActiveRecord::Schema.instance_eval do
      suppress_messages do
        create_table table, opts do |t|
          columns.each do |column, type|
            t.send type, column
          end
        end
      end
    end
    ActiveRecord::Base.clear_cache!
  end

  def add_column(*args)
    ActiveRecord::Schema.instance_eval do
      suppress_messages do
        add_column(*args)
      end
    end
    ActiveRecord::Base.clear_cache!
  end

  def create_module_model(full_name,*args,&block)
    superklass = args.first.kind_of?(Class) ? args.shift : ActiveRecord::Base

    names = full_name.split('::')

    parent_module = names[0..-1].inject(Object) do |parent,child|
      parent = parent.const_set(child.to_sym, Module.new)
    end

    parent_module ||= Object
    name = names.last

    columns = args.first || {}
    klass = parent_module.const_set name.to_sym, Class.new(superklass)
    konstant = parent_module.const_get(name.to_sym)

    if superklass == ActiveRecord::Base || superklass.abstract_class?
      create_table konstant.table_name, columns, konstant.primary_key rescue nil
    end
    klass.class_eval(&block) if block_given?
    konstant
  end

  def create_model(name, *args, &block)
    superklass = args.first.kind_of?(Class) ? args.shift : ActiveRecord::Base
    columns = args.first || {}
    klass = Object.const_set name.to_sym, Class.new(superklass)
    if superklass == ActiveRecord::Base || superklass.abstract_class?
      create_table Object.const_get(name.to_sym).table_name, columns, Object.const_get(name.to_sym).primary_key rescue nil
    end
    klass.class_eval(&block) if block_given?
    Object.const_get(name.to_sym)
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
    create_model "Beer", Beverage
  end

  def create_polymorphic_generalization
    create_model "Cannon"
    create_model "Galleon" do
      has_many :cannons, :as => :defensible
    end
  end

  def create_abstract_generalization
    create_model "Structure" do
      self.abstract_class = true
    end
    create_model "Palace", Structure
  end

  private

  def reset_config_file
    RailsERD::Config.send :remove_const, :USER_WIDE_CONFIG_FILE
    RailsERD::Config.send :const_set, :USER_WIDE_CONFIG_FILE,
      File.expand_path("../../examples/erdconfig.not_exists", __FILE__)

    RailsERD::Config.send :remove_const, :CURRENT_CONFIG_FILE
    RailsERD::Config.send :const_set, :CURRENT_CONFIG_FILE,
      File.expand_path("../../examples/erdconfig.not_exists", __FILE__)

    RailsERD.options = RailsERD.default_options.merge(Config.load)
  end

  def name_to_object_symbol_pairs(name)
    parts = name.to_s.split('::')

    return [] if parts.first == '' || parts.count == 0

    parts[1..-1].inject([[Object, parts.first.to_sym]]) do |pairs,string|
      last_parent, last_child = pairs.last

      break pairs unless last_parent.const_defined?(last_child)

      next_parent = last_parent.const_get(last_child)
      next_child = string.to_sym
      pairs << [next_parent, next_child]
    end
  end

  def remove_fully_qualified_constant(name)
    pairs = name_to_object_symbol_pairs(name)
    pairs.reverse.each do |parent, child|
      parent.send(:remove_const,child) if parent.const_defined?(child)
    end
  end

  def reset_domain
    if defined? ActiveRecord
      ActiveRecord::Base.descendants.each do |model|
        next if model.name == "ActiveRecord::InternalMetadata"
        model.reset_column_information
        remove_fully_qualified_constant(model.name)
      end
      tables_and_views.each do |table|
        ActiveRecord::Base.connection.drop_table table
      end
      ActiveRecord::Base.direct_descendants.clear
      ActiveSupport::Dependencies::Reference.clear!
      ActiveRecord::Base.clear_cache!
    end
  end

  def tables_and_views
    if ActiveRecord::VERSION::MAJOR >= 5
      ActiveRecord::Base.connection.data_sources
    else
      ActiveRecord::Base.connection.tables
    end
  end
end
