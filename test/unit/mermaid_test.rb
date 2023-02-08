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
end
