# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "rbconfig"
require "tempfile"

class CliTest < Minitest::Test
  EXECUTABLE = File.expand_path("../exe/rails-route-review", __dir__)
  REAL_ROUTES = File.read(File.join(__dir__, "fixtures", "rails-8.1.4-routes.txt"))
  REAL_ENGINE = File.read(File.join(__dir__, "fixtures", "rails-8.1.4-engine.txt"))

  def route(number, name: "", verb: "GET", path: "/users(.:format)", target: "users#index", source: nil)
    text = <<~ROUTE
      --[ Route #{number} ]-------------------------------------------------------------------
      Prefix            | #{name}
      Verb              | #{verb}
      URI               | #{path}
      Controller#Action | #{target}
    ROUTE
    text += "Source Location   | #{source}\n" if source
    text
  end

  def compare(before, after, check: false)
    Tempfile.create(["before", ".txt"]) do |first|
      Tempfile.create(["after", ".txt"]) do |second|
        first.write(before)
        first.flush
        second.write(after)
        second.flush
        arguments = [RbConfig.ruby, EXECUTABLE]
        arguments << "--check" if check
        Open3.capture3(*arguments, first.path, second.path)
      end
    end
  end

  def test_real_rails_8_expanded_output_is_accepted_and_unchanged
    stdout, stderr, status = compare(REAL_ROUTES, REAL_ROUTES, check: true)
    assert_equal 0, status.exitstatus, stderr
    assert_equal "No route changes.\n", stdout
  end

  def test_additions_and_removals_are_reported_and_check_fails
    before = route(1, name: "users") + route(2, name: "health", path: "/health(.:format)", target: "health#show")
    after = route(1, name: "users") + route(2, name: "projects", path: "/projects(.:format)", target: "projects#index")

    stdout, stderr, status = compare(before, after, check: true)
    assert_equal 1, status.exitstatus, stderr
    assert_includes stdout, "Added routes:"
    assert_includes stdout, "/projects"
    assert_includes stdout, "Removed routes:"
    assert_includes stdout, "/health"
  end

  def test_comparison_without_check_is_successful_when_routes_differ
    stdout, stderr, status = compare(route(1), route(1, path: "/other"))
    assert_equal 0, status.exitstatus, stderr
    assert_includes stdout, "Added routes:"
    assert_includes stdout, "Removed routes:"
  end

  def test_source_location_changes_are_ignored
    before = route(1, source: "/one/config/routes.rb:3")
    after = route(1, source: "/another/config/routes.rb:10")
    stdout, stderr, status = compare(before, after, check: true)
    assert_equal 0, status.exitstatus, stderr
    assert_equal "No route changes.\n", stdout
  end

  def test_action_location_changes_are_ignored
    before = route(1) + "Action Location   | app/controllers/users_controller.rb:4\n"
    after = route(1) + "Action Location   | app/controllers/users_controller.rb:20\n"
    stdout, stderr, status = compare(before, after, check: true)
    assert_equal 0, status.exitstatus, stderr
    assert_equal "No route changes.\n", stdout
  end

  def test_duplicate_routes_are_counted
    before = route(1) + route(2)
    after = route(1)
    stdout, stderr, status = compare(before, after, check: true)
    assert_equal 1, status.exitstatus, stderr
    assert_includes stdout, "Removed routes:"
    assert_equal 1, stdout.lines.count { |line| line.start_with?("- ") }
  end

  def test_order_changes_are_detected_alongside_additions
    users = route(1, name: "users")
    health = route(2, name: "health", path: "/health", target: "health#show")
    extra = route(3, name: "extra", path: "/extra", target: "extra#show")
    stdout, stderr, status = compare(users + health, health + users + extra, check: true)
    assert_equal 1, status.exitstatus, stderr
    assert_includes stdout, "Added routes:"
    assert_match(/Route order changed/, stdout)
  end

  def test_adding_a_route_does_not_claim_existing_routes_were_reordered
    users = route(1, name: "users")
    health = route(2, name: "health", path: "/health", target: "health#show")
    extra = route(3, name: "extra", path: "/extra", target: "extra#show")
    stdout, stderr, status = compare(users + health, extra + users + health, check: true)
    assert_equal 1, status.exitstatus, stderr
    assert_includes stdout, "Added routes:"
    refute_match(/Route order changed/, stdout)
  end

  def test_inserting_a_duplicate_does_not_claim_existing_routes_were_reordered
    repeated = route(1, name: "users")
    health = route(2, name: "health", path: "/health", target: "health#show")
    stdout, stderr, status = compare(repeated + health + repeated,
                                     repeated + repeated + health + repeated, check: true)
    assert_equal 1, status.exitstatus, stderr
    assert_includes stdout, "Added routes:"
    refute_match(/Route order changed/, stdout)
  end

  def test_removing_a_duplicate_does_not_claim_existing_routes_were_reordered
    repeated = route(1, name: "users")
    health = route(2, name: "health", path: "/health", target: "health#show")
    stdout, stderr, status = compare(repeated + repeated + health + repeated,
                                     repeated + health + repeated, check: true)
    assert_equal 1, status.exitstatus, stderr
    assert_includes stdout, "Removed routes:"
    refute_match(/Route order changed/, stdout)
  end

  def test_reordering_routes_is_reported_even_with_duplicates
    repeated = route(1, name: "users")
    health = route(2, name: "health", path: "/health", target: "health#show")
    stdout, stderr, status = compare(repeated + health + repeated,
                                     health + repeated + repeated, check: true)
    assert_equal 1, status.exitstatus, stderr
    assert_match(/Route order changed/, stdout)
  end

  def test_engine_sections_are_distinguished_from_application_routes
    application = route(1, name: "users")
    before = "[ Routes for application ]\n#{application}\n[ Routes for MyEngine ]\n#{application}"
    after = "[ Routes for application ]\n#{application}"
    stdout, stderr, status = compare(before, after, check: true)
    assert_equal 1, status.exitstatus, stderr
    assert_includes stdout, "Removed routes:"
    assert_includes stdout, "MyEngine"
  end

  def test_real_rails_mounted_engine_output_is_accepted
    stdout, stderr, status = compare(REAL_ENGINE, REAL_ENGINE, check: true)
    assert_equal 0, status.exitstatus, stderr
    assert_equal "No route changes.\n", stdout
  end

  def test_installed_rails_7_and_8_formatters_are_accepted
    %w[7.1.6 7.2.3.2 8.0.5.1].each do |version|
      formatted = File.read(File.join(__dir__, "fixtures", "rails-#{version}-formatter.txt"))
      stdout, stderr, status = compare(formatted, formatted, check: true)
      assert_equal 0, status.exitstatus, "Rails #{version}: #{stderr}"
      assert_equal "No route changes.\n", stdout
    end
  end

  def test_truncated_and_empty_inputs_are_errors
    ["", "--[ Route 1 ]-----\nPrefix | users\nVerb | GET\n"].each do |invalid|
      stdout, stderr, status = compare(invalid, REAL_ROUTES)
      assert_equal 2, status.exitstatus, "stdout=#{stdout.inspect} stderr=#{stderr.inspect}"
      assert_match(/error/i, stderr)
    end
  end

  def test_rails_no_routes_message_represents_empty_routes
    empty = "You don't have any routes defined!\n\nPlease add some routes in config/routes.rb.\n\nFor more information about routes, see the Rails guide: https://guides.rubyonrails.org/routing.html.\n"
    stdout, stderr, status = compare(empty, empty, check: true)
    assert_equal 0, status.exitstatus, stderr
    assert_equal "No route changes.\n", stdout
  end

  def test_usage_and_missing_files_fail_with_actionable_error
    _stdout, stderr, status = Open3.capture3(RbConfig.ruby, EXECUTABLE)
    assert_equal 2, status.exitstatus
    assert_match(/BEFORE.*AFTER/i, stderr)

    _stdout, stderr, status = Open3.capture3(RbConfig.ruby, EXECUTABLE, "/missing/routes-a.txt", "/missing/routes-b.txt")
    assert_equal 2, status.exitstatus
    assert_match(/error/i, stderr)
  end
end
