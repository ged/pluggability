#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'
require 'pluggability'
require 'spec/lib/helpers'


#
# Testing classes
#

class Plugin
	extend Pluggability
	plugin_prefixes 'plugins', 'plugins/private'
end

class SubPlugin < Plugin; end
class TestingPlugin < Plugin; end
class BlackSheep < Plugin; end
module Test
	class LoadablePlugin < Plugin; end
end


#
# Examples
#
describe Pluggability do

	before( :each ) do
		setup_logging( :fatal )
	end

	after( :each ) do
		reset_logging()
	end


	it "allows extended objects to declare one or more prefixes to use when requiring derviatives" do
		Plugin.plugin_prefixes.should == ['plugins', 'plugins/private']
	end



	context "-extended class" do

		it "knows about all of its derivatives" do
			Plugin.derivatives.keys.should include( 'sub' )
			Plugin.derivatives.keys.should include( 'subplugin' )
			Plugin.derivatives.keys.should include( 'SubPlugin' )
			Plugin.derivatives.keys.should include( SubPlugin )
		end

		it "returns derivatives directly if they're already loaded" do
			class AlreadyLoadedPlugin < Plugin; end
			Kernel.should_not_receive( :require )
			Plugin.create( 'alreadyloaded' ).should be_an_instance_of( AlreadyLoadedPlugin )
			Plugin.create( 'AlreadyLoaded' ).should be_an_instance_of( AlreadyLoadedPlugin )
			Plugin.create( 'AlreadyLoadedPlugin' ).should be_an_instance_of( AlreadyLoadedPlugin )
			Plugin.create( AlreadyLoadedPlugin ).should be_an_instance_of( AlreadyLoadedPlugin )
		end

		it "filters errors that happen when creating an instance of derivatives so they " +
			"point to the right place" do
			class PugilistPlugin < Plugin
				def initialize
					raise "Oh noes -- an error!"
				end
			end

			exception = nil
			begin
				Plugin.create('pugilist')
			rescue ::RuntimeError => err
				exception = err
			else
				fail "Expected an exception to be raised."
			end

			exception.backtrace.first.should =~ /#{__FILE__}/
		end

		it "will refuse to create an object other than one of its derivatives" do
			class Doppelgaenger; end
			expect {
				Plugin.create(Doppelgaenger)
			}.to raise_error( ArgumentError, /is not a descendent of/ )
		end


		it "will load new plugins from the require path if they're not loaded yet" do
			loaded_class = nil

			Plugin.should_receive( :require ).with( 'plugins/dazzle_plugin' ).and_return do |*args|
				loaded_class = Class.new( Plugin )
				# Simulate a named class, since we're not really requiring
				Plugin.derivatives['dazzle'] = loaded_class
				true
			end

			Plugin.create( 'dazzle' ).should be_an_instance_of( loaded_class )
		end


		it "will output a sensible description of what it tried to load if requiring a " +
			"derivative fails" do

			# at least 6 -> 3 variants * 2 paths
			Plugin.should_receive( :require ).
				at_least(6).times.
				and_return {|path| raise LoadError, "path" }

			expect {
				Plugin.create('scintillating')
			}.to raise_error( Pluggability::FactoryError, /couldn't find a \S+ named \S+.*tried \[/i )
		end


		it "will output a sensible description when a require succeeds, but it loads something unintended" do
			# at least 6 -> 3 variants * 2 paths
			Plugin.should_receive( :require ).and_return( true )

			expect {
				Plugin.create('corruscating')
			}.to raise_error( Pluggability::FactoryError, /Require of '\S+' succeeded, but didn't load a Plugin/i )
		end


		it "will re-raise the first exception raised when attempting to load a " +
			"derivative if none of the paths work" do

			# at least 6 -> 3 variants * 2 paths
			Plugin.should_receive( :require ).at_least(6).times.and_return {|path|
				raise ScriptError, "error while parsing #{path}"
			}

			expect {
				Plugin.create('portable')
			}.to raise_error( ScriptError, /error while parsing/ )
		end


		it "can preload all of its derivatives" do
			Gem.should_receive( :find_files ).with( 'plugins/*.rb' ).
				and_return([ 'plugins/first.rb' ])
			Gem.should_receive( :find_files ).with( 'plugins/private/*.rb' ).
				and_return([ 'plugins/private/second.rb', 'plugins/private/third.rb' ])

			Plugin.should_receive( :require ).with( 'plugins/first.rb' ).
				and_return( true )
			Plugin.should_receive( :require ).with( 'plugins/private/second.rb' ).
				and_return( true )
			Plugin.should_receive( :require ).with( 'plugins/private/third.rb' ).
				and_return( true )

			Plugin.load_all
		end
	end


	context "derivative of an extended class" do

		it "knows what type of plugin loads it" do
			TestingPlugin.plugin_type.should == 'Plugin'
		end

		it "raises a FactoryError if it can't figure out what type of factory loads it" do
			TestingPlugin.stub!( :ancestors ).and_return( [] )
			expect {
				TestingPlugin.plugin_type
			}.to raise_error( Pluggability::FactoryError, /couldn't find plugin base/i )
		end
	end


	context "derivative of an extended class that isn't named <Something>Plugin" do

		it "is still creatable via its full name" do
			Plugin.create( 'blacksheep' ).should be_an_instance_of( BlackSheep )
		end

		it "is loadable via its underbarred name" do
			Plugin.create( 'black_sheep' ).should be_an_instance_of( BlackSheep )
		end

	end


	context "derivative of an extended class in another namespace" do

		it "is still creatable via its derivative name" do
			Plugin.create( 'loadable' ).should be_an_instance_of( Test::LoadablePlugin )
		end

	end

end

