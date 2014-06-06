#!/usr/bin/ruby
# coding: utf-8

require 'rspec'
require 'loggability/spechelpers'
require 'pluggability'

### Mock with Rspec
RSpec.configure do |config|

	config.run_all_when_everything_filtered = true
	config.filter_run :focus
	config.order = 'random'
	config.mock_with( :rspec ) do |mock_config|
		mock_config.syntax = :expect
	end

	config.include( Loggability::SpecHelpers )
end

# vim: set nosta noet ts=4 sw=4:

