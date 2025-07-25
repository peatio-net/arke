# -*- encoding: utf-8 -*-
# stub: bitx 0.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "bitx".freeze
  s.version = "0.2.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Timothy Stranex".freeze, "Francois Paul".freeze]
  s.date = "2015-04-27"
  s.description = "BitX API wrapper".freeze
  s.email = ["timothy@bitx.co".freeze, "franc@bitx.co".freeze]
  s.homepage = "https://bitx.co/api".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.0.14".freeze
  s.summary = "Ruby wrapper for the BitX API".freeze

  s.installed_by_version = "3.5.22".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<faraday>.freeze, [">= 0".freeze])
end
