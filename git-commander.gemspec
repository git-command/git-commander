# frozen_string_literal: true

require_relative "lib/git_commander/version"

Gem::Specification.new do |spec|
  spec.name          = "git-commander"
  spec.version       = GitCommander::VERSION
  spec.authors       = ["Valentino Stoll"]
  spec.email         = ["v@codenamev.com"]

  spec.summary       = "Make your own git commands"
  spec.description   = "Build custom flexible git workflows with Ruby!"
  spec.homepage      = "https://github.com/codenamev/git-commander"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rdoc", "~> 6.2"
  spec.add_development_dependency "rspec", "< 4.0"

  spec.add_dependency "bundler", "~> 2.1", ">= 1.10.0"
end
