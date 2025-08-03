# -*- ruby -*-

require 'simplecov-cobertura'

# In .simplecov
SimpleCov.configure do
  enable_coverage :branch
  minimum_coverage 80
  refuse_coverage_drop
end if RUBY_VERSION >= "3.3.0"

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

SimpleCov.start do
  add_filter '/spec/'
end

# .simplecov
SimpleCov.start 'rails' do
  # any custom configs like groups and filters can be here at a central place
  add_group "ETL", "lib/arke/etl"
end
