require File.expand_path("../test_helper", File.dirname(__FILE__))
require "rails_erd/cli"

class CLITest < ActiveSupport::TestCase
  def setup
    RailsERD.options.filetype = :dot
    RailsERD.options.warn = false
  end

  # Generator selection ========================================================
  test "CLI should use mermaid generator by default" do
    require "rails_erd/diagram/mermaid"
    cli = RailsERD::CLI.new(Dir.pwd, {})
    assert_equal RailsERD::Diagram::Mermaid, cli.send(:generator)
  end

  test "CLI should use graphviz generator when generator option is graphviz symbol" do
    cli = RailsERD::CLI.new(Dir.pwd, { generator: :graphviz })
    assert_equal RailsERD::Diagram::Graphviz, cli.send(:generator)
  end

  test "CLI should use mermaid generator when generator option is mermaid symbol" do
    require "rails_erd/diagram/mermaid"
    cli = RailsERD::CLI.new(Dir.pwd, { generator: :mermaid })
    assert_equal RailsERD::Diagram::Mermaid, cli.send(:generator)
  end

  # Option parsing (SYMBOL_OPTIONS conversion) =================================
  test "CLI start should convert generator string to symbol" do
    # Simulate what Choice.choices returns (strings)
    Choice.stubs(:choices).returns({ "generator" => "mermaid" })
    Choice.stubs(:rest).returns([])

    # Capture the options passed to new
    captured_options = nil
    RailsERD::CLI.stubs(:new).with do |path, options|
      captured_options = options
      true
    end.returns(stub(start: nil))

    RailsERD::CLI.start

    assert_equal :mermaid, captured_options[:generator]
  end

  test "CLI start should convert mermaid_style string to symbol" do
    Choice.stubs(:choices).returns({ "mermaid_style" => "erdiagram" })
    Choice.stubs(:rest).returns([])

    captured_options = nil
    RailsERD::CLI.stubs(:new).with do |path, options|
      captured_options = options
      true
    end.returns(stub(start: nil))

    RailsERD::CLI.start

    assert_equal :erdiagram, captured_options[:mermaid_style]
  end

  test "CLI start should convert filetype string to symbol" do
    Choice.stubs(:choices).returns({ "filetype" => "pdf" })
    Choice.stubs(:rest).returns([])

    captured_options = nil
    RailsERD::CLI.stubs(:new).with do |path, options|
      captured_options = options
      true
    end.returns(stub(start: nil))

    RailsERD::CLI.start

    assert_equal :pdf, captured_options[:filetype]
  end
end
