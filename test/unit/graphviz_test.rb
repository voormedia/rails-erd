require File.expand_path("../test_helper", File.dirname(__FILE__))

class GraphvizTest < ActiveSupport::TestCase
  def setup
    RailsERD.options.file_type = :dot
    load "rails_erd/diagram/graphviz.rb"
  end
  
  def teardown
    FileUtils.rm "ERD.dot" rescue nil
    RailsERD::Diagram.send :remove_const, :Graphviz
  end
  
  def diagram(options = {})
    @diagram ||= Diagram::Graphviz.new(Domain.generate(options), options).tap do |diagram|
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

  def find_dot_node(diagram, name)
    diagram.graph.get_node(name)
  end

  def find_dot_edges(diagram)
    [].tap do |edges|
      diagram.graph.each_edge do |edge|
        edges << [edge.node_one, edge.node_two]
      end
    end
  end
  
  # Diagram properties =======================================================
  test "file name should depend on file type" do
    create_simple_domain
    begin
      assert_equal "ERD.svg", Diagram::Graphviz.create(:file_type => :svg)
    ensure
      FileUtils.rm "ERD.svg" rescue nil
    end
  end
  
  test "rank direction should be lr for horizontal orientation" do
    create_simple_domain
    assert_equal '"LR"', diagram(:orientation => :horizontal).graph[:rankdir].to_s
  end

  test "rank direction should be tb for vertical orientation" do
    create_simple_domain
    assert_equal '"TB"', diagram(:orientation => :vertical).graph[:rankdir].to_s
  end
  
  # Diagram generation =======================================================
  test "create should create output based on domain model" do
    create_model "Foo", :bar => :references, :column => :string do
      belongs_to :bar
    end
    create_model "Bar", :column => :string
    Diagram::Graphviz.create
    assert File.exists?("ERD.dot")
  end

  test "create should create output based on domain without attributes" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    Diagram::Graphviz.create
    assert File.exists?("ERD.dot")
  end
  
  test "create should create vertical output based on domain model" do
    create_model "Foo", :bar => :references, :column => :string do
      belongs_to :bar
    end
    create_model "Bar", :column => :string
    Diagram::Graphviz.create(:orientation => :vertical)
    assert File.exists?("ERD.dot")
  end

  test "create should create vertical output based on domain without attributes" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    Diagram::Graphviz.create(:orientation => :vertical)
    assert File.exists?("ERD.dot")
  end

  test "create should not create output if there are no connected models" do
    Diagram::Graphviz.create rescue nil
    assert !File.exists?("ERD.dot")
  end

  test "create should abort and complain if there are no connected models" do
    message = nil
    begin
      Diagram::Graphviz.create
    rescue => e
      message = e.message
    end
    assert_match /No \(connected\) entities found/, message
  end
  
  # Graphviz output ==========================================================
  test "generate should create directed graph" do
    create_simple_domain
    assert_equal "digraph", diagram.graph.type
  end
  
  test "generate should create node for each entity" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_equal ["Bar", "Foo"], find_dot_nodes(diagram).map(&:id).sort
  end
  
  test "generate should add label for entities" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar"
    assert_match %r{<\w+.*?>Bar</\w+>}, find_dot_node(diagram, "Bar")[:label].to_gv
  end

  test "generate should add attributes to entity labels" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar", :column => :string
    assert_match %r{<\w+.*?>column <\w+.*?>string</\w+.*?>}, find_dot_node(diagram, "Bar")[:label].to_gv
  end


  test "generate should create edge for each relationship" do
    create_model "Foo", :bar => :references do
      belongs_to :bar
    end
    create_model "Bar", :foo => :references do
      belongs_to :foo
    end
    assert_equal [["Bar", "Foo"], ["Foo", "Bar"]], find_dot_edges(diagram).sort
  end
  
  test "node records should have direction reversing braces for vertical orientation" do
    create_simple_domain
    assert_match %r(\A<{\s*<.*\|.*>\s*}>\Z)m, find_dot_node(diagram(:orientation => :vertical), "Bar")[:label].to_gv
  end

  test "node records should not have direction reversing braces for horizontal orientation" do
    create_simple_domain
    assert_match %r(\A<\s*<.*\|.*>\s*>\Z)m, find_dot_node(diagram(:orientation => :horizontal), "Bar")[:label].to_gv
  end
end
