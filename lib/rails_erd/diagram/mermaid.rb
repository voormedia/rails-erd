# encoding: utf-8
require "rails_erd/diagram"
require "erb"

module RailsERD
  class Diagram
    class Mermaid < Diagram

      attr_accessor :graph

      setup do
        self.graph = ["classDiagram"]

        # hard code to RL to make it easier to view diagrams from GitHub
        self.graph << "\tdirection RL"
      end

      each_entity do |entity, attributes|
        graph << "\tclass `#{entity}`"

        attributes.each do | attr|
          graph << "\t`#{entity}` : +#{attr.type} #{attr.name}"
        end
      end

      each_specialization do |specialization|
        from, to = specialization.generalized, specialization.specialized
        graph << "\t<<polymorphic>> `#{specialization.generalized}`"
        graph << "\t #{from.name} <|-- #{to.name}"
      end

      each_relationship do |relationship|
        from, to = relationship.source, relationship.destination
        next unless node_exists?(from) && node_exists?(to)

        graph << "\t`#{from.name}` #{relation_arrow(relationship)} `#{to.name}`"

        from.children.each do |child|
          graph << "\t`#{child.name}` #{relation_arrow(relationship)} `#{to.name}`"
        end

        to.children.each do |child|
          graph << "\t`#{from.name}` #{relation_arrow(relationship)} `#{child.name}`"
        end
      end

      save do
        raise "Saving diagram failed!\nOutput directory '#{File.dirname(filename)}' does not exist." unless File.directory?(File.dirname(filename))

        File.write(filename.gsub(/\s/,"_"), graph.uniq.join("\n"))
        filename
      end

      def filename
        "#{options.filename}.mmd"
      end

      def relation_arrow(relationship)
        arrow_body = arrow_body relationship
        arrow_head = arrow_head relationship
        arrow_tail = arrow_tail relationship

        "#{arrow_tail}#{arrow_body}#{arrow_head}"
      end

      def arrow_body(relationship)
        relationship.indirect? ? ".." : "--"
      end

      def arrow_head(relationship)
        relationship.to_many? ?  ">" : ""
      end

      def arrow_tail(relationship)
        relationship.many_to? ? "<" : ""
      end

      def node_exists?(name)
        # 適切な判定方法かというとイマイチだが変なモデル名でなければこれで動きはする
        # I'm not sure if this is the proper way to judge, but it works as long as you don't use a weird model name.
        graph.include?("\tclass `#{name}`")
      end

      def escape_name(name)
        name
      end

    end
  end
end
