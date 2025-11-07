require 'nokogiri'
module AeatValidadorNif
  module Helpers
    class XsdLoader

      # Initializes the XSD loader
      # @param main_xsd_path [String] Path to the main XSD file
      def initialize(main_xsd_path)
        @main_xsd_path = File.expand_path(main_xsd_path)
        @visited = {}
      end

      # Loads the XSD file
      # @return [Nokogiri::XML::Schema] The XSD schema
      def load
        doc = load_and_resolve(@main_xsd_path)
        Nokogiri::XML::Schema(doc.to_xml)
      end

      private

      # Loads and resolves the XSD file
      # @param path [String] Path to the XSD file
      # @return [Nokogiri::XML::Document] The XSD document
      def load_and_resolve(path)
        return @visited[path] if @visited.key?(path)

        content = File.read(path)
        doc = Nokogiri::XML(content)
        base_dir = File.dirname(path)

        doc.xpath('//xs:import | //xs:include', xs: 'http://www.w3.org/2001/XMLSchema').each do |node|
          location = node['schemaLocation']
          next unless location # a veces puede no tener `schemaLocation`

          full_path = File.expand_path(location, base_dir)
          unless File.exist?(full_path)
            warn "WARNING: Could not resolve import/include: #{location} (resolved to #{full_path})"
            next
          end

          # Recursivamente resolver los imports/includes del importado
          load_and_resolve(full_path)
          node['schemaLocation'] = full_path
        end

        @visited[path] = doc
        doc
      end
    end
  end
end
