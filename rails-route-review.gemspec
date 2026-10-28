# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "rails-route-review"
  spec.version = "0.1.0"
  spec.authors = ["Shah Zaib"]
  spec.summary = "Review changes in Rails expanded route output"
  spec.description = "Compare captured Rails routes and report additions, removals, and order changes."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6"

  spec.files = Dir["lib/**/*.rb", "exe/*", "README.md", "LICENSE", "CONTRIBUTING.md"].sort
  spec.bindir = "exe"
  spec.executables = ["rails-route-review"]
  spec.require_paths = ["lib"]
end
