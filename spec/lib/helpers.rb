#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'loggability/spechelpers'
require 'pluggability'



### Mock with Rspec
RSpec.configure do |config|
	ruby_version_vec = RUBY_VERSION.split('.').map {|c| c.to_i }.pack( "N*" )

	config.include( Loggability::SpecHelpers )
	config.treat_symbols_as_metadata_keys_with_true_values = true

	config.mock_with :rspec
end


# vim: set nosta noet ts=4 sw=4:

