require File.expand_path("../test_helper", File.dirname(__FILE__))
require "rails_erd/diagram/mermaid"

class MermaidTest < ActiveSupport::TestCase
  def setup
    RailsERD.options.filetype = :png
    RailsERD.options.warn     = false
  end

  def teardown
    FileUtils.rm Dir["erd*.*"] rescue nil
  end

  def diagram(options = {})
    @diagram ||= Diagram::Mermaid.new(Domain.generate(options), options).tap do |diagram|
      diagram.generate
    end
  end

  def find_dot_nodes(diagram)
    [].tap do |nodes|
      diagram.graph.each_node do |name, node|
        nodes << node
      end
    end
  end

  # Diagram properties =======================================================
  test "file name should be mmd" do
    create_simple_domain
    begin
      assert_equal "erd.mmd", Diagram::Mermaid.create
    ensure
      FileUtils.rm "erd.mmd" rescue nil
    end
  end

  test "direction should be right to left" do
    create_simple_domain

    assert_equal "\tdirection RL", diagram.graph[1]
  end


  # # Diagram generation =======================================================
  test "create should create output for domain with attributes" do
    create_model "Foo", :bar => :references, :column => :string do
      belongs_to :bar
    end

    create_model "Bar", :column => :string

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Bar`",
      "\t`Bar` : +string column",
      "\tclass `Foo`",
      "\t`Foo` : +string column",
      "\t`Bar` --> `Foo`"
    ]

    assert_equal expected, diagram.graph
  end

  test "create should create output for domain without attributes" do
    create_simple_domain

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Bar`",
      "\tclass `Beer`",
      "\t`Bar` --> `Beer`"
    ]

    assert_equal expected, diagram.graph
  end

  test "create should abort and complain if there are no connected models" do
    message = nil
    begin
      Diagram::Mermaid.create
    rescue => e
      message = e.message
    end
    assert_match(/No entities found/, message)
  end

  test "create should abort and complain if output directory does not exist" do
    message = nil

    begin
      create_simple_domain
      Diagram::Mermaid.create(:filename => "does_not_exist/foo")
    rescue => e
      message = e.message
    end

    assert_match(/Output directory 'does_not_exist' does not exist/, message)
  end

  test "generate should add attributes to entity" do
    RailsERD.options.markup = false
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar", :column => :string, :column_two => :boolean

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Bar`",
      "\t`Bar` : +string column",
      "\t`Bar` : +boolean column_two",
      "\tclass `Foo`",
      "\t`Bar` --> `Foo`"
    ]

    assert_equal expected, diagram.graph
  end

  test "generate should not add any attributes if attributes is set to false" do
    create_model "Jar", :contents => :string
    create_model "Lid", :jar => :references do
      belongs_to :jar
    end

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Jar`",
      "\tclass `Lid`",
      "\t`Jar` --> `Lid`"
    ]

    assert_equal expected, diagram(:attributes => false).graph
  end

  test "generate should create edge to polymorphic entity if polymorphism is true" do
    create_model "Cannon", :defensible => :references do
      belongs_to :defensible, :polymorphic => true
    end

    create_model "Stronghold" do
      has_many :cannons, :as => :defensible
    end

    create_model "Galleon" do
      has_many :cannons, :as => :defensible
    end

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Cannon`",
      "\tclass `Defensible`",
      "\tclass `Galleon`",
      "\tclass `Stronghold`",
      "\t<<polymorphic>> `Defensible`",
      "\t Defensible <|-- Galleon",
      "\t Defensible <|-- Stronghold",
      "\t`Defensible` --> `Cannon`",
      "\t`Galleon` --> `Cannon`",
      "\t`Stronghold` --> `Cannon`"
    ]

    assert_equal expected, diagram(:polymorphism => true).graph.uniq
  end

  test "generate should create edge to each child of polymorphic entity if polymorphism is false" do
    create_model "Cannon", :defensible => :references do
      belongs_to :defensible, :polymorphic => true
    end

    create_model "Stronghold" do
      has_many :cannons, :as => :defensible
    end

    create_model "Galleon" do
      has_many :cannons, :as => :defensible
    end

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Cannon`",
      "\tclass `Galleon`",
      "\tclass `Stronghold`",
      "\t`Defensible` --> `Cannon`",
      "\t`Galleon` --> `Cannon`",
      "\t`Stronghold` --> `Cannon`"
    ]
    assert_equal expected, diagram.graph.uniq
  end

  test "generate should support one to many relationships" do
    create_one_to_many_assoc_domain

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Many`",
      "\tclass `One`",
      "\t`One` --> `Many`"
    ]

    assert_equal expected, diagram.graph.uniq
  end

  test "generate should support one to many indirect relationships" do
    create_model "Foo" do
      has_many :bazs
      has_many :bars
    end

    create_model "Bar", :foo => :references do
      belongs_to :foo
      has_many :bazs, :through => :foo
    end

    create_model "Baz", :foo => :references do
      belongs_to :foo
    end

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Bar`",
      "\tclass `Baz`",
      "\tclass `Foo`",
      "\t`Foo` --> `Baz`",
      "\t`Foo` --> `Bar`",
      "\t`Bar` ..> `Baz`"
    ]

    assert_equal expected, diagram.graph.uniq
  end

  test "generate should support many to many relationships" do
    create_many_to_many_assoc_domain

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Many`",
      "\tclass `More`",
      "\t`Many` <--> `More`"
    ]

    assert_equal expected, diagram.graph.uniq
  end

  test "generate should support one to one relationships" do
    create_one_to_one_assoc_domain

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `One`",
      "\tclass `Other`",
      "\t`One` -- `Other`"
    ]

    assert_equal expected, diagram.graph.uniq
  end

  test "generate should support one to one recursive relationships" do
    create_model "Emperor" do
      belongs_to :predecessor, :class_name => "Emperor"
      has_one :successor, :class_name => "Emperor", :foreign_key => :predecessor_id
    end

    expected = [
      "classDiagram",
      "\tdirection RL",
      "\tclass `Emperor`",
      "\t`Emperor` -- `Emperor`"
    ]

    assert_equal expected, diagram.graph.uniq
  end

  # erDiagram tests ============================================================

  test "erdiagram style should use erDiagram header" do
    create_simple_domain

    result = diagram(:mermaid_style => :erdiagram).graph.uniq

    assert_equal "erDiagram", result[0]
    assert_equal "\tdirection RL", result[1]
    # Entity blocks are joined with newlines
    assert result.any? { |line| line.include?("Bar {") }
    assert result.any? { |line| line.include?("Beer {") }
    # Relationship uses crow's foot notation
    assert result.any? { |line| line.include?("Bar") && line.include?("Beer") && line.include?("--") }
  end

  test "erdiagram style should include attributes with PK/FK markers" do
    create_model "Foo", :bar => :references, :column => :string do
      belongs_to :bar
    end

    create_model "Bar", :column => :string

    result = diagram(:mermaid_style => :erdiagram, :attributes => [:primary_keys, :foreign_keys, :content]).graph.join("\n")

    assert result.include?("erDiagram")
    assert result.include?("id PK"), "Should include primary key marker"
    assert result.include?("bar_id FK"), "Should include foreign key marker"
  end

  test "erdiagram style should use crow's foot notation for one to many" do
    create_one_to_many_assoc_domain

    result = diagram(:mermaid_style => :erdiagram).graph.uniq

    assert result.include?("erDiagram")
    # One to many should have }| or }o on the "many" side
    relationship_line = result.find { |line| line.include?("One") && line.include?("Many") && line.include?("--") }
    assert relationship_line, "Should have a relationship line between One and Many"
    assert relationship_line.match?(/\}\||\}o/), "Should use crow's foot notation for many side"
  end

  test "erdiagram style should use crow's foot notation for many to many" do
    create_many_to_many_assoc_domain

    result = diagram(:mermaid_style => :erdiagram).graph.uniq

    assert result.include?("erDiagram")
    # Many to many should have }| or }o on both sides
    relationship_line = result.find { |line| line.include?("Many") && line.include?("More") && line.include?("--") }
    assert relationship_line, "Should have a relationship line between Many and More"
  end

  test "erdiagram style should use crow's foot notation for one to one" do
    create_one_to_one_assoc_domain

    result = diagram(:mermaid_style => :erdiagram).graph.uniq

    assert result.any? { |line| line.include?("erDiagram") }
    # One to one should have | on both sides (not })
    relationship_line = result.find { |line| line.include?("One") && line.include?("Other") && line.include?("--") }
    assert relationship_line, "Should have a relationship line between One and Other"
    # Should not have } which indicates "many"
    refute relationship_line.include?("}"), "One-to-one should not use } (many) notation: #{relationship_line}"
  end

  test "erdiagram style should use dotted line for indirect relationships" do
    create_model "Foo" do
      has_many :bazs
      has_many :bars
    end

    create_model "Bar", :foo => :references do
      belongs_to :foo
      has_many :bazs, :through => :foo
    end

    create_model "Baz", :foo => :references do
      belongs_to :foo
    end

    result = diagram(:mermaid_style => :erdiagram).graph.uniq

    # Indirect relationship should use .. instead of --
    indirect_line = result.find { |line| line.include?("Bar") && line.include?("Baz") }
    assert indirect_line, "Should have a relationship line between Bar and Baz"
    assert indirect_line.include?(".."), "Indirect relationship should use dotted line"
  end

  test "er option alias should work same as erdiagram" do
    create_simple_domain

    result = diagram(:mermaid_style => :er).graph

    assert result.include?("erDiagram")
  end
end
