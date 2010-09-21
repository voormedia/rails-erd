module RailsERD
  class Relationship
    class Cardinality
      N = Infinity = 1.0/0
      
      CARDINALS = {
        [1, 1] => :one_to_one,
        [1, N] => :one_to_many,
        [N, 1] => :many_to_one,
        [N, N] => :many_to_many
      }

      attr_reader :source_range
      
      attr_reader :destination_range

      def initialize(source_range, destination_range)
        @source_range = compose_range(source_range)
        @destination_range = compose_range(destination_range)
      end
      
      def name
        CARDINALS[type]
      end
      
      def source_optional?
        source_range.first < 1
      end
      
      def destination_optional?
        destination_range.first < 1
      end
      
      def inverse
        self.class.new destination_range, source_range
      end
      
      CARDINALS.each do |type, name|
        class_eval <<-RUBY
          def #{name}?
            type == #{type.inspect}
          end
        RUBY
      end
      
      def ==(other) # @private :nodoc:
        source_range == other.source_range and destination_range == other.destination_range
      end
      
      def <=>(other) # @private :nodoc:
        compare_with(other, &:type).nonzero? or
        compare_with(other) { |x| x.source_range.first + x.destination_range.first }.nonzero? or
        compare_with(other) { |x| x.source_range.last + x.destination_range.last }.nonzero? or
        compare_with(other) { |x| x.source_range.last }.nonzero? or
        compare_with(other) { |x| x.destination_range.last }
      end
      
      def inspect # @private :nodoc:
        "#<#{self.class}:0x%.14x (%s,%s) => (%s,%s)>" %
          [object_id << 1, source_range.first, source_range.last, destination_range.first, destination_range.last]
      end
      
      protected

      def source_type
        source_range.last == 1 ? 1 : N
      end
      
      def destination_type
        destination_range.last == 1 ? 1 : N
      end
      
      def type
        [source_type, destination_type]
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
