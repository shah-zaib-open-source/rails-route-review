# frozen_string_literal: true

require "optparse"

module RailsRouteReview
  class CLI
    def self.run(argv, stdout: $stdout, stderr: $stderr)
      check = false
      options = OptionParser.new do |opts|
        opts.banner = "Usage: rails-route-review [--check] BEFORE AFTER"
        opts.on("--check", "Exit 1 when route output has changed") { check = true }
        opts.on("-h", "--help", "Show this help") do
          stdout.puts opts
          return 0
        end
      end
      args = options.parse(argv)
      raise OptionParser::MissingArgument, "BEFORE and AFTER" unless args.size == 2

      before = Parser.parse(File.read(args[0], encoding: "UTF-8"))
      after = Parser.parse(File.read(args[1], encoding: "UTF-8"))
      comparison = Comparison.new(before, after)
      stdout.print comparison.report
      check && comparison.changed? ? 1 : 0
    rescue OptionParser::ParseError, ParseError, SystemCallError, ArgumentError, EncodingError => e
      stderr.puts "Error: #{e.message}"
      2
    end
  end
end
