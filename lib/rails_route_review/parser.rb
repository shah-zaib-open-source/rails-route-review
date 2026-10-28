# frozen_string_literal: true

module RailsRouteReview
  class ParseError < StandardError; end

  # Rails' expanded route output includes source locations that vary by machine.
  # Only the displayed route fields and section are part of the comparison.
  class Parser
    FIELDS = ["Prefix", "Verb", "URI", "Controller#Action"].freeze
    OPTIONAL_FIELDS = ["Source Location", "Action Location"].freeze
    ROUTE_HEADER = /\A--\[ Route \d+ \]-*\s*\z/
    SECTION_HEADER = /\A\[ Routes for (.+) \]\s*\z/

    def self.parse(text)
      new.parse(text)
    end

    def parse(text)
      routes = []
      section = "application"
      fields = nil
      saw_empty = false

      text.each_line.with_index(1) do |raw_line, line_number|
        line = raw_line.chomp
        next if line.strip.empty?

        if (match = SECTION_HEADER.match(line))
          routes << build_route(section, fields) if fields
          fields = nil
          section = match[1]
        elsif ROUTE_HEADER.match?(line)
          routes << build_route(section, fields) if fields
          fields = {}
        elsif line == "You don't have any routes defined!" || line == "No routes defined."
          raise ParseError, "unexpected empty-routes message at line #{line_number}" if fields
          saw_empty = true
        elsif line == "Please add some routes in config/routes.rb." || line.start_with?("For more information about routes, see the Rails guide:")
          raise ParseError, "unexpected routes guidance at line #{line_number}" unless saw_empty
        elsif (match = /\A\s*([^|]+?)\s*\|\s?(.*)\z/.match(line))
          raise ParseError, "field outside a route at line #{line_number}" unless fields
          key, value = match[1].strip, match[2].strip
          unless FIELDS.include?(key) || OPTIONAL_FIELDS.include?(key)
            raise ParseError, "unknown field #{key.inspect} at line #{line_number}"
          end
          raise ParseError, "duplicate field #{key.inspect} at line #{line_number}" if fields.key?(key)
          fields[key] = value
        else
          raise ParseError, "unrecognized output at line #{line_number}"
        end
      end

      routes << build_route(section, fields) if fields
      raise ParseError, "no expanded routes found" if routes.empty? && !saw_empty
      routes
    end

    private

    def build_route(section, fields)
      missing = FIELDS - fields.keys
      raise ParseError, "incomplete route; missing #{missing.join(', ')}" unless missing.empty?
      raise ParseError, "route URI is empty" if fields["URI"].empty?

      [section, *FIELDS.map { |field| fields[field] }].freeze
    end
  end
end
