source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Handle bundled gems explicitly - these come with Ruby 3.3.8
gem "psych", "~> 5.1.2", force_ruby_platform: true
gem "stringio", "~> 3.1.0", force_ruby_platform: true

# Core application
gemspec

# CLI framework
gem "clamp", "~> 1.3.1"

# Exchange integrations
gem "binance", "~> 1.2", git: "https://github.com/caherrerapa/binance.git"
gem "fiddler-rb", "~> 0.1.3", git: "https://github.com/genki/fiddler.git"

# Monitoring and metrics
gem "prometheus_exporter", "~> 2.0.6"

# Logging (should be moved to gemspec as runtime dependency)
gem "logger", "~> 1.6"

group :development, :test do
  # Debugging tools
  gem "pry", "~> 0.14.2"
  gem "byebug", "~> 11.1", platforms: [:mri, :mingw, :x64_mingw]
  gem "debug", "~> 1.8", platforms: [:mri]
  gem "irb", "~> 1.12.0"  # Use older stable version

  # Testing framework
  gem "rspec", "~> 3.13"
  gem "shoulda-matchers", "~> 4.1.2"  # Keep current version for stability
  gem "faker", "~> 3.4.1"
  gem "webmock", "~> 3.23"

  # Code quality and linting
  gem "rubocop", "~> 1.57"
  gem "rubocop-performance", "~> 1.19"
  gem "rubocop-rspec", "~> 2.24"

  # Test coverage
  gem "simplecov", "~> 0.22", require: false
  gem "simplecov-cobertura", "~> 2.1"

  # Development utilities
  gem "bump", "~> 0.10"
  gem "rexml", "~> 3.3"
  gem "mime-types", "~> 3.5"
  gem "em-websocket", "~> 0.5.3"
end

