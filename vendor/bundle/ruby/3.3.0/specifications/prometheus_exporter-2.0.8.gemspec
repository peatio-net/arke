# -*- encoding: utf-8 -*-
# stub: prometheus_exporter 2.0.8 ruby lib

Gem::Specification.new do |s|
  s.name = "prometheus_exporter".freeze
  s.version = "2.0.8".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sam Saffron".freeze]
  s.date = "2023-01-20"
  s.description = "Prometheus metric collector and exporter for Ruby".freeze
  s.email = ["sam.saffron@gmail.com".freeze]
  s.executables = ["prometheus_exporter".freeze]
  s.files = ["bin/prometheus_exporter".freeze]
  s.homepage = "https://github.com/discourse/prometheus_exporter".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "prometheus_exporter will only bind to localhost by default as of v0.5".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Prometheus Exporter".freeze

  s.installed_by_version = "3.5.22".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<webrick>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0.69".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 2.1.4".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.15.0".freeze])
  s.add_development_dependency(%q<guard>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<mini_racer>.freeze, ["~> 0.5.0".freeze])
  s.add_development_dependency(%q<guard-minitest>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<oj>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, ["~> 0.8.3".freeze])
  s.add_development_dependency(%q<minitest-stub-const>.freeze, ["~> 0.6".freeze])
  s.add_development_dependency(%q<rubocop-discourse>.freeze, ["> 2".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, ["~> 2.3".freeze])
  s.add_development_dependency(%q<activerecord>.freeze, ["~> 6.0.0".freeze])
  s.add_development_dependency(%q<redis>.freeze, ["> 5".freeze])
  s.add_development_dependency(%q<m>.freeze, [">= 0".freeze])
end
