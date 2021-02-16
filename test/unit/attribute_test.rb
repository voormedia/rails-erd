# encoding: utf-8
require File.expand_path("../test_helper", File.dirname(__FILE__))

class AttributeTest < ActiveSupport::TestCase
  def with_native_limit(type, new_limit)
    ActiveRecord::Base.connection.singleton_class.class_eval do
      undef :native_database_types
      define_method(:native_database_types) do
        super().tap do |types|
          types[type][:limit] = new_limit
        end
      end
    end
    yield
  ensure
    ActiveRecord::Base.connection.singleton_class.class_eval do
      undef :native_database_types
      define_method(:native_database_types) do
        super()
      end
    end
  end

  def create_attribute(model, name)
    Domain::Attribute.new(Domain.generate, model, model.columns_hash[name])
  end

  # Attribute ================================================================
  test "column should return database column" do
    create_model "Foo", :my_column => :string
    assert_equal Foo.columns_hash["my_column"],
      Domain::Attribute.from_model(Domain.new, Foo).reject(&:primary_key?).first.column
  end

  test "from_model should return attributes with sorted order if sort is true" do
    RailsERD.options[:sort] = true
    create_model "Foo"
    add_column :foos, :a, :string
    assert_equal %w{a id}, Domain::Attribute.from_model(Domain.new, Foo).map(&:name)
  end

  test "from_model should return attributes with original order if sort is false" do
    RailsERD.options[:sort] = false
    create_model "Foo"
    add_column :foos, :a, :string
    assert_equal %w{id a}, Domain::Attribute.from_model(Domain.new, Foo).map(&:name)
  end

  test "from_model should return attributes with PK first if prepend_primary is true" do
    RailsERD.options[:sort]            = true
    RailsERD.options[:prepend_primary] = true

    create_model "Foo"
    add_column :foos, :a, :string

    assert_equal %w{id a}, Domain::Attribute.from_model(Domain.new, Foo).map(&:name)
  end

  test "spaceship should sort attributes by name" do
    create_model "Foo", :a => :string, :b => :string, :c => :string
    a = create_attribute(Foo, "a")
    b = create_attribute(Foo, "b")
    c = create_attribute(Foo, "c")
    assert_equal [a, b, c], [c, a, b].sort
  end

  test "inspect should show column" do
    create_model "Foo", :my_column => :string
    assert_match %r{#<RailsERD::Domain::Attribute:.* @name="my_column" @type=:string>},
      Domain::Attribute.new(Domain.new, Foo, Foo.columns_hash["my_column"]).inspect
  end

  test "type should return attribute type" do
    create_model "Foo", :a => :binary
    assert_equal :binary, create_attribute(Foo, "a").type
  end

  test "type should return native type if unsupported by rails" do
    create_model "Foo"
    ActiveRecord::Schema.define do
      suppress_messages do
        add_column "foos", "a", "REAL"
      end
    end
    assert_equal :real, create_attribute(Foo, "a").type
  end

  # Attribute properties =====================================================
  test "mandatory should return false by default" do
    create_model "Foo", :column => :string
    assert_equal false, create_attribute(Foo, "column").mandatory?
  end

  test "mandatory should return true if attribute has a presence validator" do
    create_model "Foo", :column => :string do
      validates :column, :presence => true
    end
    assert_equal true, create_attribute(Foo, "column").mandatory?
  end

  test "mandatory should return true if attribute has a not null constraint" do
    create_model "Foo"
    add_column :foos, :column, :string, :null => false, :default => ""
    assert_equal true, create_attribute(Foo, "column").mandatory?
  end

  test "primary_key should return false by default" do
    create_model "Bar", :my_key => :integer
    assert_equal false, create_attribute(Bar, "my_key").primary_key?
  end

  test "primary_key should return true if column is used as primary key" do
    create_model "Bar", :my_key => :integer do
      self.primary_key = :my_key
    end
    assert_equal true, create_attribute(Bar, "my_key").primary_key?
  end

  test "foreign_key should return false by default" do
    create_model "Foo", :bar => :references
    assert_equal false, create_attribute(Foo, "bar_id").foreign_key?
  end

  test "foreign_key should return true if it is used in an association" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_equal true, create_attribute(Foo, "bar_id").foreign_key?
  end

  test "foreign_key should return true if it is used in a remote association" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_many :foos
    end
    assert_equal true, create_attribute(Foo, "bar_id").foreign_key?
  end

  test "timestamp should return false by default" do
    create_model "Foo", :created => :datetime
    assert_equal false, create_attribute(Foo, "created").timestamp?
  end

  test "timestamp should return true if it is named created_at/on or updated_at/on" do
    create_model "Foo", :created_at => :string, :updated_at => :string, :created_on => :string, :updated_on => :string
    assert_equal [true] * 4, [create_attribute(Foo, "created_at"), create_attribute(Foo, "updated_at"),
      create_attribute(Foo, "created_on"), create_attribute(Foo, "updated_on")].collect(&:timestamp?)
  end

  test "inheritance should return false by default" do
    create_model "Foo", :type => :string, :alternative => :string do
      self.inheritance_column = :alternative
    end
    assert_equal false, create_attribute(Foo, "type").inheritance?
  end

  test "inheritance should return if this column is used for single table inheritance" do
    create_model "Foo", :type => :string, :alternative => :string do
      self.inheritance_column = :alternative
    end
    assert_equal true, create_attribute(Foo, "alternative").inheritance?
  end

  test "content should return true by default" do
    create_model "Foo", :my_first_column => :string
    assert_equal true, create_attribute(Foo, "my_first_column").content?
  end

  test "content should return false for primary keys, foreign keys, timestamps and inheritance columns" do
    create_model "Book", :type => :string, :created_at => :datetime, :case => :references do
      belongs_to :case
    end
    create_model "Case"
    assert_equal [false] * 4, %w{id type created_at case_id}.map { |a| create_attribute(Book, a).content? }
  end

  # Type descriptions ========================================================
  test "type_description should return short type description" do
    create_model "Foo", :a => :binary
    assert_equal "binary", create_attribute(Foo, "a").type_description
  end

  test "type_description should return short type description if unsupported by rails" do
    create_model "Foo"
    ActiveRecord::Schema.define do
      suppress_messages do
        add_column "foos", "a", "REAL"
      end
    end
    assert_equal "real", create_attribute(Foo, "a").type_description
  end

  test "type_description should return short type description without limit if standard" do
    with_native_limit :string, 456 do
      create_model "Foo"
      add_column :foos, :my_str, :string, :limit => 255
      ActiveRecord::Base.connection.native_database_types[:string]
      assert_equal "string (255)", create_attribute(Foo, "my_str").type_description
    end
  end

  test "type_description should return short type description with limit if nonstandard" do
    with_native_limit :string, 456 do
      create_model "Foo"
      add_column :foos, :my_str, :string, :limit => 456
      assert_equal "string", create_attribute(Foo, "my_str").type_description
    end
  end

  test "type_description should append hair space and low asterisk if field is mandatory" do
    create_model "Foo", :a => :integer do
      validates_presence_of :a
    end
    assert_equal "integer ∗", create_attribute(Foo, "a").type_description
  end

  test "type_description should return short type description with scale and precision for decimal types if nonstandard" do
    create_model "Foo"
    add_column :foos, :num, :decimal, :precision => 5, :scale => 2
    assert_equal "decimal (5,2)", create_attribute(Foo, "num").type_description
  end

  test "limit should return nil if there is no limit" do
    create_model "Foo"
    add_column :foos, :my_txt, :text
    assert_nil create_attribute(Foo, "my_txt").limit
  end

  test "limit should return nil if equal to standard database limit" do
    with_native_limit :string, 456 do
      create_model "Foo"
      add_column :foos, :my_str, :string, :limit => 456
      assert_nil create_attribute(Foo, "my_str").limit
    end
  end

  test "limit should return limit if nonstandard" do
    with_native_limit :string, 456 do
      create_model "Foo"
      add_column :foos, :my_str, :string, :limit => 255
      assert_equal 255, create_attribute(Foo, "my_str").limit
    end
  end

  test "limit should return precision for decimal columns if nonstandard" do
    create_model "Foo"
    add_column :foos, :num, :decimal, :precision => 5, :scale => 2
    assert_equal 5, create_attribute(Foo, "num").limit
  end

  test "limit should return nil for decimal columns if equal to standard database limit" do
    create_model "Foo"
    add_column :foos, :num, :decimal
    assert_nil create_attribute(Foo, "num").limit
  end

  test "limit should return nil if type is unsupported by rails" do
    create_model "Foo"
    ActiveRecord::Schema.define do
      suppress_messages do
        add_column "foos", "a", "REAL"
      end
    end
    assert_nil create_attribute(Foo, "a").limit
  end

  test "limit should return nil for oddball column types that misuse the limit attribute" do
    create_model "Business", :location => :integer do
      define_singleton_method :limit do
        # https://github.com/voormedia/rails-erd/issues/21
        { :srid => 4326, :type => "point", :geographic => true }
      end
    end

    attribute = create_attribute(Business, "location")
    assert_nil attribute.limit
  end

  test "scale should return scale for decimal columns if nonstandard" do
    create_model "Foo"
    add_column :foos, :num, :decimal, :precision => 5, :scale => 2
    assert_equal 2, create_attribute(Foo, "num").scale
  end

  test "scale should return nil for decimal columns if equal to standard database limit" do
    create_model "Foo"
    add_column :foos, :num, :decimal
    assert_nil create_attribute(Foo, "num").scale
  end

  test "scale should return zero for decimal columns if left to default setting when specifying precision" do
    create_model "Foo"
    add_column :foos, :num, :decimal, :precision => 5
    assert_equal 0, create_attribute(Foo, "num").scale
  end

  test "scale should return nil if type is unsupported by rails" do
    create_model "Foo"
    ActiveRecord::Schema.define do
      suppress_messages do
        add_column "foos", "a", "REAL"
      end
    end
    assert_nil create_attribute(Foo, "a").scale
  end

  test "scale should return nil for oddball column types that misuse the scale attribute" do
    create_model "Kobold", :size => :integer do
      define_method :scale do
        1..5
      end
    end
    attribute = create_attribute(Kobold, "size")
    assert_nil attribute.scale
  end
end
