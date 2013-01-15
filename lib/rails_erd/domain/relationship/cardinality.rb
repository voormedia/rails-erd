module RailsERD
  class Domain
    class Relationship
      class Cardinality
        extend Inspectable
        inspection_attributes :source_range, :destination_range

        N = Infinity = 1.0/0 # And beyond.

        CLASSES = {
          [1, 1] => :one_to_one,
          [1, N] => :one_to_many,
          [N, 1] => :many_to_one,
          [N, N] => :many_to_many
        } # @private :nodoc:

        # Returns a range that indicates the source (left) cardinality.
        attr_reader :source_range

        # Returns a range that indicates the destination (right) cardinality.
        attr_reader :destination_range

        # Create a new cardinality based on a source range and a destination
        # range. These ranges describe which number of values are valid.
        def initialize(source_range, destination_range) # @private :nodoc:
          @source_range = compose_range(source_range)
          @destination_range = compose_range(destination_range)
        end

        # Returns the name of this cardinality, based on its two cardinal
        # numbers (for source and destination). Can be any of
        # +:one_to_one:+, +:one_to_many+, or +:many_to_many+. The name
        # +:many_to_one+ also exists, but Rails ERD always normalises these
        # kinds of relationships by inverting them, so they become
        # +:one_to_many+ associations.
        #
        # You can also call the equivalent method with a question mark, which
        # will return true if the name corresponds to that method. For example:
        #
        #   cardinality.one_to_one?
        #   #=> true
        #   cardinality.one_to_many?
        #   #=> false
        def name
          CLASSES[cardinality_class]
        end

        # Returns +true+ if the source (left side) is not mandatory.
        def source_optional?
          source_range.first < 1
        end

        # Returns +true+ if the destination (right side) is not mandatory.
        def destination_optional?
          destination_range.first < 1
        end

        # Returns the inverse cardinality. Destination becomes source, source
        # becomes destination.
        def inverse
          self.class.new destination_range, source_range
        end

        CLASSES.each do |cardinality_class, name|
          class_eval <<-RUBY
            def #{name}?
              cardinality_class == #{cardinality_class.inspect}
            end
          RUBY
        end

        def ==(other) # @private :nodoc:
          source_range == other.source_range and destination_range == other.destination_range
        end

        def <=>(other) # @private :nodoc:
          (cardinality_class <=> other.cardinality_class).nonzero? or
          compare_with(other) { |x| x.source_range.first + x.destination_range.first }.nonzero? or
          compare_with(other) { |x| x.source_range.last + x.destination_range.last }.nonzero? or
          compare_with(other) { |x| x.source_range.last }.nonzero? or
          compare_with(other) { |x| x.destination_range.last }
        end

        # Returns an array with the cardinality classes for the source and
        # destination of this cardinality. Possible return values are:
        # <tt>[1, 1]</tt>, <tt>[1, N]</tt>, <tt>[N, N]</tt>, and (in theory)
        # <tt>[N, 1]</tt>.
        def cardinality_class
          [source_cardinality_class, destination_cardinality_class]
        end

        protected

        # The cardinality class of the source (left side). Either +1+ or +Infinity+.
        def source_cardinality_class
          source_range.last == 1 ? 1 : N
        end

        # The cardinality class of the destination (right side). Either +1+ or +Infinity+.
        def destination_cardinality_class
          destination_range.last == 1 ? 1 : N
        end

        private

        def compose_range(r)
          return r..r if r.kind_of?(Integer) && r > 0
          return (r.begin)..(r.end - 1) if r.exclude_end?
          r
        end

        def compare_with(other, &block)
          yield(self) <=> yield(other)
        end
      end
    end
  end
end
