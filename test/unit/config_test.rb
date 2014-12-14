# encoding: utf-8
require File.expand_path("../test_helper", File.dirname(__FILE__))

class ConfigTest < ActiveSupport::TestCase
  def normalize_value(key, value)
    RailsERD::Config.new.send(:normalize_value, key, value)
  end

  test "load_config_gile should return blank hash when neither CURRENT_CONFIG_FILE nor USER_WIDE_CONFIG_FILE exist." do
    expected_hash = {}
    assert_equal expected_hash, RailsERD::Config.load
  end

  test "load_config_gile should return a hash from USER_WIDE_CONFIG_FILE when only USER_WIDE_CONFIG_FILE exists." do
    RailsERD::Config.send :remove_const, :USER_WIDE_CONFIG_FILE
    RailsERD::Config.send :const_set, :USER_WIDE_CONFIG_FILE,
      File.expand_path("../../../examples/erdconfig.example", __FILE__)

    expected_hash = {
      :attributes     => [:content, :foreign_key, :inheritance],
      :disconnected   => true,
      :filename       => "erd",
      :filetype       => :pdf,
      :indirect       => true,
      :inheritance    => false,
      :markup         => true,
      :notation       => :simple,
      :orientation    => :horizontal,
      :polymorphism   => false,
      :warn           => true,
      :title          => "sample title",
      :exclude        => nil,
      :only           => nil
    }
    assert_equal expected_hash, RailsERD::Config.load
  end

  test "load_config_gile should return a hash from CURRENT_CONFIG_FILE when only CURRENT_CONFIG_FILE exists." do
    RailsERD::Config.send :remove_const, :CURRENT_CONFIG_FILE
    RailsERD::Config.send :const_set, :CURRENT_CONFIG_FILE,
      File.expand_path("../../../examples/erdconfig.another_example", __FILE__)

    expected_hash = {
      :attributes => [:primary_key]
    }
    assert_equal expected_hash, RailsERD::Config.load
  end

  test "load_config_gile should return a hash from CURRENT_CONFIG_FILE overriding USER_WIDE_CONFIG_FILE when both of them exist." do
    RailsERD::Config.send :remove_const, :USER_WIDE_CONFIG_FILE
    RailsERD::Config.send :const_set, :USER_WIDE_CONFIG_FILE,
      File.expand_path("../../../examples/erdconfig.example", __FILE__)

    RailsERD::Config.send :remove_const, :CURRENT_CONFIG_FILE
    RailsERD::Config.send :const_set, :CURRENT_CONFIG_FILE,
      File.expand_path("../../../examples/erdconfig.another_example", __FILE__)

    expected_hash = {
      :attributes => [:primary_key],
      :disconnected   => true,
      :filename       => "erd",
      :filetype       => :pdf,
      :indirect       => true,
      :inheritance    => false,
      :markup         => true,
      :notation       => :simple,
      :orientation    => :horizontal,
      :polymorphism   => false,
      :warn           => true,
      :title          => "sample title",
      :exclude        => nil,
      :only           => nil
    }
    assert_equal expected_hash, RailsERD::Config.load
  end

  test "normalize_value should return symbols in an array when key is :attributes and value is a comma-joined string." do
    assert_equal [:content, :foreign_keys], normalize_value(:attributes, "content,foreign_keys")
  end

  test "normalize_value should return symbols in an array when key is :attributes and value is strings in an array." do
    assert_equal [:content, :primary_keys], normalize_value(:attributes, ["content", "primary_keys"])
  end
end
