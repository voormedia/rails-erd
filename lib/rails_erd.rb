require "active_support/ordered_options"
require "rails_erd/railtie" if defined? Rails

# Rails ERD provides several options that allow you to customise the
# generation of the diagram and the domain model itself. Currently, the
# following options are supported:
#
# type:: The file type of the generated diagram. Defaults to +:pdf+, which
#        is the recommended format. Other formats may render significantly
#        worse than a PDF file.
# orientation:: The direction of the hierarchy of entities. Either +:horizontal+
#               or +:vertical+. Defaults to +:horizontal+.
# suppress_warnings:: When set to +true+, no warnings are printed to the
#                     command line while processing the domain model. Defaults
#                     to +false+.
# exclude_timestamps:: Excludes timestamp columns (<tt>created_at/on</tt> and
#                      <tt>updated_at/on</tt>) from attribute lists. Defaults
#                      to +true+.
# exclude_primary_keys:: Excludes primary key columns from attribute lists.
#                        Defaults to +true+.
# exclude_foreign_keys:: Excludes foreign key columns from attribute lists.
#                        Defaults to +true+.
module RailsERD
  class << self
    # Access to default options. Any instance of RailsERD::Domain and
    # RailsERD::Diagram will use these options unless overridden.
    attr_accessor :options
  end

  self.options = ActiveSupport::OrderedOptions[
    :type, :pdf,
    :orientation, :horizontal,
    :exclude_timestamps, true,
    :exclude_primary_keys, true,
    :exclude_foreign_keys, true,
    :suppress_warnings, false
  ]
end
