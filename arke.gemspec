# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = "arke"
  spec.version = File.read("VERSION").strip
  spec.authors = ["Louis B.", "Camille M."]
  spec.email = ["cmeulien@openware.com"]

  spec.summary = "Arke trading bot & library"
  spec.description = "Arke trading bot & library"
  spec.homepage = "https://www.openware.com"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
#  spec.files = Dir.chdir(File.expand_path(__dir__)) do
#    `git ls-files -z`.split("\x0").reject {|f| f.match(%r{^(test|spec|features)/}) }
#  end

  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) {|f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rbtree", "~> 0.4.4"
  spec.add_dependency "faraday", "~> 1.4"
  spec.add_dependency "faye", "~> 1.2"
  spec.add_dependency "eventmachine", "~> 1.2"
  spec.add_dependency "em-synchrony", "~> 1.0"
  spec.add_dependency "colorize", "~> 0.8.1"
  spec.add_dependency "rack", "~> 2.2"
  spec.add_dependency 'logger'

  ## Exchanges API libraries
  spec.add_dependency "bitx", "~> 0.2.2"
end
