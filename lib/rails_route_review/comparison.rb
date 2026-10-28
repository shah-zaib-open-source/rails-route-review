# frozen_string_literal: true

module RailsRouteReview
  class Comparison
    def initialize(before, after)
      @before, @after = before, after
    end

    def changed?
      @before != @after
    end

    def report
      return "No route changes.\n" unless changed?

      before_counts = counts(@before)
      after_counts = counts(@after)
      removed = excess(@before, after_counts)
      added = excess(@after, before_counts)
      common_counts = before_counts.to_h { |route, count| [route, [count, after_counts[route]].min] }
      before_common = shared(@before, common_counts)
      after_common = shared(@after, common_counts)

      lines = []
      unless removed.empty?
        lines << "Removed routes:"
        removed.each { |route| lines << "- #{format_route(route)}" }
      end
      unless added.empty?
        lines << "Added routes:"
        added.each { |route| lines << "+ #{format_route(route)}" }
      end
      if before_common != after_common && reordered?(common_counts.values.sum)
        lines << "Route order changed (common routes):"
        lines << "Before:"
        before_common.each { |route| lines << "  #{format_route(route)}" }
        lines << "After:"
        after_common.each { |route| lines << "  #{format_route(route)}" }
      end
      lines.join("\n") + "\n"
    end

    private

    def counts(routes)
      routes.each_with_object(Hash.new(0)) { |route, result| result[route] += 1 }
    end

    def excess(routes, other_counts)
      available = other_counts.dup
      routes.reject do |route|
        if available[route].positive?
          available[route] -= 1
          true
        else
          false
        end
      end
    end

    def shared(routes, common_counts)
      remaining = common_counts.dup
      routes.select do |route|
        if remaining.fetch(route, 0).positive?
          remaining[route] -= 1
          true
        else
          false
        end
      end
    end

    # Identical routes have no unique identity. Greedily matching the first
    # occurrence can mistake an added duplicate for a reorder, so check whether
    # all common occurrences can be matched in their original order.
    def reordered?(common_count)
      return false if common_count.zero?

      shorter, longer = [@before, @after].sort_by(&:length)
      lengths = Array.new(shorter.length + 1, 0)

      longer.each do |route|
        diagonal = 0
        shorter.each_with_index do |candidate, index|
          previous = lengths[index + 1]
          lengths[index + 1] = if route == candidate
            diagonal + 1
          else
            [lengths[index], previous].max
          end
          diagonal = previous
        end
        return false if lengths.last == common_count
      end

      true
    end

    def format_route(route)
      section, prefix, verb, uri, target = route
      "[#{section}] #{verb.empty? ? 'ANY' : verb} #{uri} name=#{prefix.inspect} target=#{target.inspect}"
    end
  end
end
