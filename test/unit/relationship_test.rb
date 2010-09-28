require File.expand_path("../test_helper", File.dirname(__FILE__))

class RelationshipTest < ActiveSupport::TestCase
  # Relationship =============================================================
  test "inspect should show source and destination" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_match %r{#<RailsERD::Relationship:.* @source=Bar @destination=Foo>}, domain.relationships.first.inspect
  end
  
  test "source should return relationship source" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [domain.entity_for(Bar)], domain.relationships.map(&:source)
  end
  
  test "destination should return relationship destination" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [domain.entity_for(Foo)], domain.relationships.map(&:destination)
  end
  
  # Relationship properties ==================================================
  test "mutual should return false for one way relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [false], domain.relationships.map(&:mutual?)
  end
  
  test "mutual should return true for mutual relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [true], domain.relationships.map(&:mutual?)
  end
  
  test "recursive should return false for ordinary relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [false], domain.relationships.map(&:recursive?)
  end
  
  test "recursive should return true for self referencing relationship" do
    create_model "Foo", :foo => :references do
      belongs_to :foo
    end
    domain = Domain.generate
    assert_equal [true], domain.relationships.map(&:recursive?)
  end
  
  test "indirect should return false for ordinary relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [false], domain.relationships.map(&:indirect?)
  end
  
  test "indirect should return false for non mutual ordinary relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [false], domain.relationships.map(&:indirect?)
  end
  
  test "indirect should return true if relationship is a through association" do
    create_model "Foo", :baz => :references, :bar => :references do
      belongs_to :baz
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
      has_many :bazs, :through => :foos
    end
    create_model "Baz" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal true, domain.relationships.find { |rel|
      rel.source.model == Bar and rel.destination.model == Baz }.indirect?
  end
  
  test "strength should return one for relationship with one association" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [1], domain.relationships.map(&:strength)
  end

  test "strength should return two for relationship with two associations" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [2], domain.relationships.map(&:strength)
  end

  test "strength should return number of associations that make up the relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
      belongs_to :special_bar, :class_name => "Bar", :foreign_key => :bar_id
    end
    create_model "Bar" do
      has_many :foos
      has_many :special_foos, :class_name => "Foo", :foreign_key => :bar_id
    end
    domain = Domain.generate
    assert_equal [4], domain.relationships.map(&:strength)
  end
  
  # Cardinality classes ======================================================
  test "cardinality should be one to one for has_one associations" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_one :foo
    end
    domain = Domain.generate

    # In these test, we are liberal with the number of assertions per test.
    assert_equal [:one_to_one], domain.relationships.map(&:cardinality).map(&:name)

    assert_equal [true], domain.relationships.map(&:one_to_one?)
    assert_equal [false], domain.relationships.map(&:one_to_many?)
    assert_equal [false], domain.relationships.map(&:many_to_many?)

    assert_equal [true], domain.relationships.map(&:one_to?)
    assert_equal [false], domain.relationships.map(&:many_to?)
    assert_equal [true], domain.relationships.map(&:to_one?)
    assert_equal [false], domain.relationships.map(&:to_many?)
  end
  
  test "cardinality should be one to many for has_many associations" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate

    assert_equal [:one_to_many], domain.relationships.map(&:cardinality).map(&:name)
    assert_equal [false], domain.relationships.map(&:one_to_one?)
    assert_equal [true], domain.relationships.map(&:one_to_many?)
    assert_equal [false], domain.relationships.map(&:many_to_many?)

    assert_equal [true], domain.relationships.map(&:one_to?)
    assert_equal [false], domain.relationships.map(&:many_to?)
    assert_equal [false], domain.relationships.map(&:to_one?)
    assert_equal [true], domain.relationships.map(&:to_many?)
  end
  
  test "cardinality should be many to many for has_and_belongs_to_many associations" do
    create_table "bars_foos", :foo_id => :integer, :bar_id => :integer
    create_model "Foo" do
      has_and_belongs_to_many :bars
    end
    create_model "Bar" do
      has_and_belongs_to_many :foos
    end
    domain = Domain.generate

    assert_equal [:many_to_many], domain.relationships.map(&:cardinality).map(&:name)

    assert_equal [false], domain.relationships.map(&:one_to_one?)
    assert_equal [false], domain.relationships.map(&:one_to_many?)
    assert_equal [true], domain.relationships.map(&:many_to_many?)

    assert_equal [false], domain.relationships.map(&:one_to?)
    assert_equal [true], domain.relationships.map(&:many_to?)
    assert_equal [false], domain.relationships.map(&:to_one?)
    assert_equal [true], domain.relationships.map(&:to_many?)
  end
  
  test "cardinality should be one to many for multiple associations with maximum cardinality of has_many" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_one :foo
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [:one_to_many], domain.relationships.map(&:cardinality).map(&:name)
  end
  
  test "cardinality should be one to many if forward association is missing" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [:one_to_many], domain.relationships.map(&:cardinality).map(&:name)
  end
end
