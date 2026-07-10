# frozen_string_literal: true

require File.expand_path("../test_helper", File.dirname(__FILE__))
require "rails_erd/diagram/tbls"
require "json"

class TblsTest < ActiveSupport::TestCase
  def setup
    RailsERD.options.warn = false
  end

  def diagram(options = {})
    Diagram::Tbls.new(Domain.generate(options), options).tap(&:generate)
  end

  def payload(options = {})
    diagram(options).send(:schema_payload)
  end

  def table(payload, name)
    payload[:tables].find { |t| t[:name] == name }
  end

  def constraint(table, type)
    table[:constraints].find { |c| c[:type] == type }
  end

  # File output ==============================================================
  test "filename has json extension" do
    create_simple_domain
    result = Diagram::Tbls.create
    assert result.end_with?(".json"), "Expected .json, got #{result}"
  end

  test "written file is valid JSON parseable by tbls schema shape" do
    create_simple_domain
    file = Diagram::Tbls.create
    parsed = JSON.parse(File.read(file))

    assert parsed.key?("tables")
    assert parsed["tables"].is_a?(Array)
    assert parsed["tables"].all? { |t| t.key?("name") && t.key?("columns") }
  end

  # Tables ===================================================================
  test "emits one table per concrete entity using db table name" do
    create_simple_domain
    p = payload

    names = p[:tables].map { |t| t[:name] }.sort
    assert_equal %w[bars beers], names
  end

  test "columns carry name, type, nullable; default and comment only when set" do
    create_model "Widget", name: :string, qty: :integer do
      belongs_to :gizmo, optional: true
    end
    create_model "Gizmo"

    widgets = table(payload, "widgets")
    name_col = widgets[:columns].find { |c| c[:name] == "name" }

    assert name_col[:type].start_with?("varchar"), "Expected varchar type, got #{name_col[:type]}"
    assert_equal true, name_col[:nullable]
    # tbls schema rejects null comments/defaults — they must be omitted, not nulled.
    refute_includes name_col.keys, :default
    refute_includes name_col.keys, :comment
  end

  # Primary keys =============================================================
  test "every table gets a PRIMARY KEY constraint" do
    create_simple_domain

    table(payload, "beers")[:constraints].tap do |constraints|
      pk = constraints.find { |c| c[:type] == "PRIMARY KEY" }
      assert pk, "expected a PRIMARY KEY constraint"
      assert_equal ["id"], pk[:columns]
      assert_equal "beers_pkey", pk[:name]
    end
  end

  # Foreign keys =============================================================
  test "belongs_to becomes a FOREIGN KEY constraint on the owning table" do
    create_simple_domain  # Beer belongs_to :bar

    beers = table(payload, "beers")
    fk = constraint(beers, "FOREIGN KEY")

    assert fk, "expected a FOREIGN KEY constraint on beers"
    assert_equal ["bar_id"], fk[:columns]
    assert_equal "bars", fk[:referenced_table]
    assert_equal ["id"], fk[:referenced_columns]
  end

  test "FK def string is parseable by tbls parser" do
    create_simple_domain
    fk = constraint(table(payload, "beers"), "FOREIGN KEY")

    assert_equal "FOREIGN KEY (bar_id) REFERENCES bars(id)", fk[:def]
  end

  test "has_many side does not get an FK; only the belongs_to side does" do
    create_one_to_many_assoc_domain  # One has_many :many; Many belongs_to :one

    ones = table(payload, "ones")
    manies = table(payload, "manies")

    assert_nil constraint(ones, "FOREIGN KEY"), "owner side must not have an FK"
    assert constraint(manies, "FOREIGN KEY"), "belongs_to side must have an FK"
  end

  test "polymorphic associations are skipped (no synthetic FK)" do
    create_polymorphic_generalization  # Cannon belongs_to :defensible, polymorphic; Galleon has_many :cannons, as: :defensible

    cannons = table(payload(polymorphism: true), "cannons")
    assert_nil constraint(cannons, "FOREIGN KEY"),
      "polymorphic belongs_to has no concrete target — must not emit FK"
  end

  test "indirect (has_many :through) relationships do not produce extra constraints" do
    create_model "Author" do
      has_many :authorships
      has_many :books, through: :authorships
    end
    create_model "Book" do
      has_many :authorships
      has_many :authors, through: :authorships
    end
    create_model "Authorship", author: :references, book: :references do
      belongs_to :author
      belongs_to :book
    end

    authorships = table(payload, "authorships")
    fk_targets = authorships[:constraints]
      .select { |c| c[:type] == "FOREIGN KEY" }
      .map { |c| c[:referenced_table] }
      .sort

    # Exactly two FKs — author + book — not duplicated by the indirect relationship.
    assert_equal %w[authors books], fk_targets
  end

  # Schema-level payload =====================================================
  test "top-level payload has a name and a tables array" do
    create_simple_domain
    p = payload

    assert p[:name].is_a?(String) && !p[:name].empty?
    assert p[:tables].is_a?(Array)
  end
end
