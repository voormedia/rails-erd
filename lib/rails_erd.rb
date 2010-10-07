require "active_support/ordered_options"
require "rails_erd/railtie" if defined? Rails

# Rails ERD provides several options that allow you to customise the
# generation of the diagram and the domain model itself. For an overview of
# all options available in Rails ERD, see README.rdoc.
#
# You can specify the option on the command line if you use Rails ERD with
# Rake:
#
#   % rake erd orientation=vertical title='My model diagram'
#
# When using Rails ERD from within Ruby, you can set the options on the
# RailsERD namespace module:
#
#   RailsERD.options.orientation = :vertical
#   RailsERD.options.title = "My model diagram"
module RailsERD
  class << self
    # Access to default options. Any instance of RailsERD::Domain and
    # RailsERD::Diagram will use these options unless overridden.
    attr_accessor :options
  end
  
  module Inspectable # @private :nodoc:
    def inspect_with(*attributes)
      attribute_inspection = attributes.collect { |attribute|
        " @#{attribute}=\#{[Symbol, String].include?(#{attribute}.class) ? #{attribute}.inspect : #{attribute}}"
      }.join
      class_eval <<-RUBY
        def inspect
          "#<\#{self.class}:0x%.14x#{attribute_inspection}>" % (object_id << 1)
        end
      RUBY
    end
  end

  self.options = ActiveSupport::OrderedOptions[
    :attributes, :regular,
    :disconnected, true,
    :filename, "ERD",
    :filetype, :pdf,
    :indirect, true,
    :inheritance, false,
    :notation, :simple,
    :orientation, :horizontal,
    :warn, true,
    :title, true
  ]
end
