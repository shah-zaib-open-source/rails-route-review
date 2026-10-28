# Rails Route Review

Compare two Rails route listings to make changes easier to review. The tool
reports added and removed routes, duplicate counts, and changes to the order of
routes shared by both listings. It is designed for branch comparisons and CI.

This is an early, independent project; it is not affiliated with Rails. A route
listing is a useful review aid, not a complete description of routing behavior.

## Usage

Capture expanded route listings from the same application and environment on
each revision. Run each capture in its corresponding checkout:

```sh
bin/rails routes --expanded > /tmp/before-routes.txt
# Switch to the revision you want to review, then:
bin/rails routes --expanded > /tmp/after-routes.txt
```

Run the tool from this project directory, passing the paths to both captures:

```sh
ruby exe/rails-route-review /tmp/before-routes.txt /tmp/after-routes.txt
ruby exe/rails-route-review --check /tmp/before-routes.txt /tmp/after-routes.txt
```

`--check` exits with status 1 when the captured routes differ and 0 when they
match. Invalid input, missing files, or incorrect usage exit with status 2.
Without `--check`, a successful comparison exits 0 even when changes are
reported. Use `--help` for command-line help.

## What it compares

The comparison uses the displayed route section, prefix, verb, URI, and
controller/action. Source and action locations are ignored, because paths and
line numbers can change without a route changing. Matching retains duplicate
routes and their order. Identical duplicate routes are matched in their
existing order where possible. The input must be Rails' expanded output; malformed or
unsupported input is rejected rather than silently treated as an empty list.

Output depends on the Rails version, environment, application configuration,
and mounted engines. Compare captures made with consistent settings. Changes
to constraints or application behavior that are not present in the listing
cannot be detected, and a clean report does not establish compatibility or
security. Route listings can expose application details: review them before
sharing them publicly.

## Development

Ruby 2.6 or later is required for the command. The tests also require Minitest.
The included fixtures cover Rails 7.1, 7.2, 8.0, and 8.1 route formatters;
the Rails 8.1 fixtures include actual route sets and a mounted engine. The other
versions have not yet been verified with full applications. Run the test suite
with:

```sh
ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |file| require File.expand_path(file) }'
```

To build and install the gem locally:

```sh
gem build rails-route-review.gemspec
gem install ./rails-route-review-0.1.0.gem
rails-route-review --check /tmp/before-routes.txt /tmp/after-routes.txt
```

The gem has not been published to RubyGems.

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidance.

## License

[MIT](LICENSE).
