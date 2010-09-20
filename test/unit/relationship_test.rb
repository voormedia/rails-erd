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
  
  # Cardinality ==============================================================
  test "cardinality should return one to one for has_one associations" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_one :foo
    end
    domain = Domain.generate
    assert_equal [Relationship::Cardinality::OneToOne], domain.relationships.map(&:cardinality)
  end
  
  test "cardinality should return one to many for has_many associations" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [Relationship::Cardinality::OneToMany], domain.relationships.map(&:cardinality)
  end
  
  test "cardinality should return many to many for has_and_belongs_to_many associations" do
    create_table "bars_foos", :foo_id => :integer, :bar_id => :integer
    create_model "Foo" do
      has_and_belongs_to_many :bars
    end
    create_model "Bar" do
      has_and_belongs_to_many :foos
    end
    domain = Domain.generate
    assert_equal [Relationship::Cardinality::ManyToMany], domain.relationships.map(&:cardinality)
  end
  
  test "cardinality should return one to many for multiple associations with maximum cardinality of has_many" do
    create_model "Foo", :bar => :references
    create_model "Bar" do
      has_one :foo
      has_many :foos
    end
    domain = Domain.generate
    assert_equal [Relationship::Cardinality::OneToMany], domain.relationships.map(&:cardinality)
  end
  
  test "cardinality should return one to many if forward association is missing" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    domain = Domain.generate
    assert_equal [Relationship::Cardinality::OneToMany], domain.relationships.map(&:cardinality)
  end
  
  # test "cardinality should return zero or more for has_many association" do
  #   create_model "Foo", :bar => :references do
  #     belongs_to :bar
  #   end
  #   create_model "Bar" do
  #     has_many :foos
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::ZeroOrMore, domain.relationships.first.cardinality
  # end
  # 
  # test "cardinality should return one or more for validated has_many association" do
  #   create_model "Foo", :bar => :references do
  #     belongs_to :bar
  #   end
  #   create_model "Bar" do
  #     has_many :foos
  #     validates :foos, :presence => true
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::OneOrMore, domain.relationships.first.cardinality
  # end
  # 
  # test "cardinality should return zero or more for has_many association with foreign database constraint" do
  #   create_model "Foo" do
  #     belongs_to :bar
  #   end
  #   add_column :foos, :bar_id, :integer, :null => false, :default => 0
  #   create_model "Bar" do
  #     has_many :foos
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::ZeroOrMore, domain.relationships.first.cardinality
  # end
  # 
  # test "cardinality should return zero or one for has_one association" do
  #   create_model "Foo", :bar => :references do
  #     belongs_to :bar
  #   end
  #   create_model "Bar" do
  #     has_one :foo
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::ZeroOrOne, domain.relationships.first.cardinality
  # end
  # 
  # test "cardinality should return exactly one for validated has_one association" do
  #   create_model "Foo", :bar => :references do
  #     belongs_to :bar
  #   end
  #   create_model "Bar" do
  #     has_one :foo
  #     validates :foo, :presence => true
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::ExactlyOne, domain.relationships.first.cardinality
  # end
  # 
  # test "cardinality should return exactly one for has_one association with foreign database constraint" do
  #   create_model "Foo" do
  #     belongs_to :bar
  #   end
  #   add_column :foos, :bar_id, :integer, :null => false, :default => 0
  #   create_model "Bar" do
  #     has_one :foo
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::ZeroOrOne, domain.relationships.first.cardinality
  # end
  # 
  # # Reverse cardinality ======================================================
  # test "reverse_cardinality should return nil if reverse association is missing" do
  #   create_model "Foo", :bar => :references
  #   create_model "Bar" do
  #     has_many :foos
  #   end
  #   domain = Domain.generate
  #   assert_nil domain.relationships.first.reverse_cardinality
  # end
  # 
  # test "reverse_cardinality should return zero or one for has_many association" do
  #   create_model "Foo", :bar => :references do
  #     belongs_to :bar
  #   end
  #   create_model "Bar" do
  #     has_many :foos
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::ZeroOrOne, domain.relationships.first.reverse_cardinality
  # end
  # 
  # test "reverse_cardinality should return exactly one for validated has_many association" do
  #   create_model "Foo", :bar => :references do
  #     belongs_to :bar
  #     validates :bar, :presence => true
  #   end
  #   create_model "Bar" do
  #     has_many :foos
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::ExactlyOne, domain.relationships.first.reverse_cardinality
  # end
  # 
  # test "reverse_cardinality should return zero or one for has_one association" do
  #   create_model "Foo", :bar => :references do
  #     belongs_to :bar
  #   end
  #   create_model "Bar" do
  #     has_one :foo
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::ZeroOrOne, domain.relationships.first.reverse_cardinality
  # end
  # 
  # test "reverse_cardinality should return exactly one for validated has_one association" do
  #   create_model "Foo", :bar => :references do
  #     belongs_to :bar
  #     validates :bar, :presence => true
  #   end
  #   create_model "Bar" do
  #     has_one :foo
  #   end
  #   domain = Domain.generate
  #   assert_equal Cardinality::ExactlyOne, domain.relationships.first.reverse_cardinality
  # end
end
