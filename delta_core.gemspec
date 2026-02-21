# frozen_string_literal: true

require_relative "lib/delta_core/version"

Gem::Specification.new do |spec|
  spec.name = "delta_core"
  spec.version = DeltaCore::VERSION
  spec.authors = ["Mykhailo Marusyk"]
  spec.email = ["mmarusyk1@gmail.com"]
  spec.platform = Gem::Platform::RUBY

  spec.summary = "Snapshot, compare, and diff class state with structured delta results."
  spec.description = "DeltaCore persists explicit snapshots of confirmed class state " \
                     "and compares them against current state to produce structured, deterministic " \
                     "delta results. It distinguishes added, removed, and modified entities, supports " \
                     "pluggable comparison strategies (quantity, replace, merge), and integrates with " \
                     "Rails via a configurable DSL with transactional safety and idempotent delta generation."
  spec.homepage = "https://github.com/mmarusyk/delta_core"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mmarusyk/delta_core"
  spec.metadata["changelog_uri"] = "https://github.com/mmarusyk/delta_core/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
