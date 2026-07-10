require File.expand_path("../test_helper", File.dirname(__FILE__))
require "rails_erd/diagram/mermaid"

class MermaidTest < ActiveSupport::TestCase
  def setup
    RailsERD.options.filetype = :png
    RailsERD.options.warn     = false
    RailsERD.options.mermaid_style = :classdiagram
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
  test "file name should have mmd extension" do
    create_simple_domain
    result = Diagram::Mermaid.create
    assert result.end_with?(".mmd"), "Expected filename to end with .mmd, got: #{result}"
  end

  test "direction should be top to bottom by default" do
    create_simple_domain

    assert_equal "\tdirection TB", diagram.graph[1]
  end

  test "direction should be left to right when orientation is vertical" do
    create_simple_domain

    d = Diagram::Mermaid.new(Domain.generate, orientation: :vertical).tap { |diag| diag.generate }
    assert_equal "\tdirection LR", d.graph[1]
  end


  # # Diagram generation =======================================================
  test "create should create output for domain with attributes" do
    create_model "Foo", :bar => :references, :column => :string do
      belongs_to :bar
    end

    create_model "Bar", :column => :string

    expected = [
      "classDiagram",
      "\tdirection TB",
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
      "\tdirection TB",
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
      "\tdirection TB",
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
      "\tdirection TB",
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
      "\tdirection TB",
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
      "\tdirection TB",
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
      "\tdirection TB",
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
      "\tdirection TB",
      "\tclass `Bar`",
      "\tclass `Baz`",
      "\tclass `Foo`",
      "\t`Foo` --> `Bar`",
      "\t`Bar` ..> `Baz`",
      "\t`Foo` --> `Baz`"
    ]

    assert_equal expected, diagram.graph.uniq
  end

  test "generate should support many to many relationships" do
    create_many_to_many_assoc_domain

    expected = [
      "classDiagram",
      "\tdirection TB",
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
      "\tdirection TB",
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
      "\tdirection TB",
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
    assert_equal "\tdirection TB", result[1]
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

  # Namespace tests (Issue #450) ================================================

  test "classDiagram should handle namespaced model names" do
    create_model "Post"
    create_module_model "Admin::Author", :post => :references do
      belongs_to :post
    end

    result = diagram.graph

    assert result.include?("classDiagram")
    # Backticks should properly escape the namespace
    assert result.any? { |line| line.include?("`Admin::Author`") }, "Should wrap namespaced entity in backticks"
    assert result.any? { |line| line.include?("`Post`") && line.include?("`Admin::Author`") }, "Relationship should use backticks for both entities"
  end

  test "erDiagram should wrap namespaced model names in double quotes" do
    create_model "Post"
    create_module_model "Admin::Author", :post => :references do
      belongs_to :post
    end

    result = diagram(:mermaid_style => :erdiagram).graph.join("\n")

    assert result.include?("erDiagram")
    # Double quotes are required for entity names containing ::
    assert result.include?('"Admin::Author"'), "Should wrap namespaced entity in double quotes, got: #{result}"
    # Relationship line should also quote the namespaced entity (order may vary)
    assert result.match?(/("Admin::Author".*--.*Post|Post.*--.*"Admin::Author")/), "Relationship should quote namespaced entity"
  end

  test "erDiagram should handle multiple namespaced models in relationships" do
    create_module_model "Admin::User" do
      has_many :posts, class_name: "Blog::Post"
    end
    create_module_model "Blog::Post", :admin_user => :references do
      belongs_to :admin_user, class_name: "Admin::User"
    end

    result = diagram(:mermaid_style => :erdiagram).graph.join("\n")

    assert result.include?('"Admin::User"'), "Should quote Admin::User"
    assert result.include?('"Blog::Post"'), "Should quote Blog::Post"
  end

  test "erDiagram should quote namespaced entities in specialization relationships" do
    create_model "Vehicle", :type => :string
    # Create a namespaced subclass (STI)
    create_module_model "Transport::Car", Vehicle

    # STI requires inheritance: true option
    result = diagram(:mermaid_style => :erdiagram, :inheritance => true).graph.join("\n")

    # The specialization relationship should quote the namespaced entity
    assert result.include?('"Transport::Car"'), "Should quote namespaced specialized entity"
    # Verify the specialization relationship line also quotes it
    assert result.match?(/Vehicle.*--.*"Transport::Car"/), "Specialization relationship should quote namespaced entity"
  end

  # Namespace clustering tests (Issue #479) =====================================

  test "classDiagram with cluster should group entities by namespace" do
    create_model "Post"
    create_module_model "Admin::Author", :post => :references do
      belongs_to :post
    end
    create_module_model "Admin::Role"

    result = diagram(:cluster => true).graph.join("\n")

    assert result.include?("classDiagram")
    # Should have namespace block for Admin
    assert result.include?("namespace Admin {"), "Should have namespace block for Admin"
    # Author and Role should be inside the Admin namespace
    assert result.match?(/namespace Admin \{[^}]*class `Author`/m), "Author should be inside Admin namespace"
    assert result.match?(/namespace Admin \{[^}]*class `Role`/m), "Role should be inside Admin namespace"
  end

  test "classDiagram with cluster should place entities without namespace outside blocks" do
    create_model "Post"
    create_module_model "Admin::Author", :post => :references do
      belongs_to :post
    end

    result = diagram(:cluster => true).graph.join("\n")

    # Post should appear before any namespace block
    post_index = result.index("class `Post`")
    namespace_index = result.index("namespace Admin {")
    assert post_index < namespace_index, "Entities without namespace should appear before namespace blocks"
  end

  test "classDiagram with cluster should handle nested namespaces" do
    create_model "Post"
    create_module_model "Admin::Users::Role", :post => :references do
      belongs_to :post
    end

    result = diagram(:cluster => true).graph.join("\n")

    # Nested namespace should use dot notation (Admin.Users)
    assert result.include?("namespace Admin.Users {"), "Should convert :: to . in namespace names"
    assert result.match?(/namespace Admin\.Users \{[^}]*class `Role`/m), "Role should be inside Admin.Users namespace"
  end

  test "classDiagram with cluster should render relationships outside namespace blocks" do
    create_model "Post"
    create_module_model "Admin::Author", :post => :references do
      belongs_to :post
    end

    result = diagram(:cluster => true).graph.join("\n")

    # Relationship should appear after the namespace block closes
    namespace_close_index = result.index("}")
    relationship_index = result.index("`Post` --> `Admin::Author`")
    assert relationship_index > namespace_close_index, "Relationships should appear after namespace blocks"
  end

  test "erDiagram with cluster should emit warning and render flat" do
    create_model "Post"
    create_module_model "Admin::Author", :post => :references do
      belongs_to :post
    end

    test_diagram = nil

    warning_output = collect_stdout do
      domain = Domain.generate
      test_diagram = Diagram::Mermaid.new(domain, :cluster => true, :mermaid_style => :erdiagram, :warn => true)
      test_diagram.generate
    end

    result = test_diagram.graph.join("\n")

    # Should emit warning about clustering not supported
    assert warning_output.include?("Clustering is not supported"), "Should warn about clustering not supported in erDiagram"
    # Should still render the diagram (flat, no namespace blocks)
    assert result.include?("erDiagram")
    refute result.include?("namespace"), "erDiagram should not have namespace blocks"
  end

  test "classDiagram with cluster false should not group entities" do
    create_model "Post"
    create_module_model "Admin::Author", :post => :references do
      belongs_to :post
    end

    result = diagram(:cluster => false).graph.join("\n")

    assert result.include?("classDiagram")
    # Should NOT have namespace blocks
    refute result.include?("namespace"), "cluster: false should not create namespace blocks"
    # Should use full entity names
    assert result.include?("class `Admin::Author`"), "Should use full entity name without clustering"
  end

  test "classDiagram with cluster and inheritance should emit entities before specializations" do
    create_model "Vehicle", :type => :string
    create_module_model "Transport::Car", Vehicle

    result = diagram(:cluster => true, :inheritance => true).graph.join("\n")

    # Entity class definitions should appear BEFORE specialization lines
    vehicle_class_index = result.index("class `Vehicle`")
    polymorphic_index = result.index("<<polymorphic>>")
    inheritance_index = result.index("<|--")

    assert vehicle_class_index, "Should have Vehicle class definition.\nGot:\n#{result}"
    assert polymorphic_index, "Should have polymorphic marker.\nGot:\n#{result}"
    assert inheritance_index, "Should have inheritance relationship.\nGot:\n#{result}"

    # The key assertion: class definitions must come BEFORE specializations
    assert vehicle_class_index < polymorphic_index,
      "Class definitions should appear before polymorphic markers.\n" \
      "Got:\n#{result}"
    assert vehicle_class_index < inheritance_index,
      "Class definitions should appear before inheritance relationships.\n" \
      "Got:\n#{result}"
  end
end
