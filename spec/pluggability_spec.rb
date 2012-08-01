#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'
require 'logger'
require 'pluggability'

require 'spec/lib/helpers'


describe Pluggability do

	before( :each ) do
		setup_logging( :fitharn )
		Loggability.level = :debug
	end

	after( :each ) do
		reset_logging()
	end


	it "allows extended objects to declare one or more prefixes to use when requiring derviatives" do
		pluginclass = Class.new
		pluginclass.extend( Pluggability )
		pluginclass.plugin_prefixes "plugins", "plugins/private"
		pluginclass.plugin_prefixes.should == ["plugins", "plugins/private"]
	end


	context "-extended class" do

		before( :all ) do
			@plugin = Class.new do
				def name; "Plugin"; end
				extend Pluggability
				plugin_prefixes "plugins", "plugins/private"
			end
			@subplugin = Class.new( @plugin ) { def name; "SubPlugin"; end }
		end


		it "knows about all of its derivatives" do
			@plugin.derivatives.keys.should include( 'sub' )
			@plugin.derivatives.keys.should include( 'subplugin' )
			@plugin.derivatives.keys.should include( 'SubPlugin' )
			@plugin.derivatives.keys.should include( @subplugin )
		end

		it "returns derivatives directly if they're already loaded" do
			class AlreadyLoadedPlugin < @plugin; end
			Kernel.should_not_receive( :require )
			@plugin.create( 'alreadyloaded' ).should be_an_instance_of( AlreadyLoadedPlugin )
			@plugin.create( 'AlreadyLoaded' ).should be_an_instance_of( AlreadyLoadedPlugin )
			@plugin.create( 'AlreadyLoadedPlugin' ).should be_an_instance_of( AlreadyLoadedPlugin )
			@plugin.create( AlreadyLoadedPlugin ).should be_an_instance_of( AlreadyLoadedPlugin )
		end

		it "filters errors that happen when creating an instance of derivatives so they " +
			"point to the right place" do
			class PugilistPlugin < @plugin
				def initialize
					raise "Oh noes -- an error!"
				end
			end

			expect {
				@plugin.create('pugilist')
			}.to raise_error( RuntimeError, /#{__FILE__}/ )
		end

		it "will refuse to create an object other than one of its derivatives" do
			class Doppelgaenger; end
			expect {
				@plugin.create(Doppelgaenger)
			}.to raise_error( ArgumentError, /is not a descendent of/ )
		end


		it "will load new plugins from the require path if they're not loaded yet" do
			loaded_class = nil

			@plugin.should_receive( :require ).with( 'plugins/dazzle_plugin' ).and_return do |*args|
				loaded_class = Class.new( @plugin )
				# Simulate a named class, since we're not really requiring
				@plugin.derivatives['dazzle'] = loaded_class 
				true
			end

			@plugin.create( 'dazzle' ).should be_an_instance_of( loaded_class )
		end


		it "will output a sensible description of what it tried to load if requiring a " +
			"derivative fails" do

			# at least 6 -> 3 variants * 2 paths
			@plugin.should_receive( :require ).
				at_least(6).times.
				and_return {|path| raise LoadError, "path" }

			expect {
				@plugin.create('scintillating')
			}.to raise_error( FactoryError, /couldn't find a \S+ named \S+.*tried \[/i )
		end


		it "will output a sensible description when a require succeeds, but it loads something unintended" do
			# at least 6 -> 3 variants * 2 paths
			@plugin.should_receive( :require ).and_return( true )

			expect {
				@plugin.create('corruscating')
			}.to raise_error( FactoryError, /Require of '\S+' succeeded, but didn't load a @plugin/i )
		end


		it "will re-raise the first exception raised when attempting to load a " +
			"derivative if none of the paths work" do

			# at least 6 -> 3 variants * 2 paths
			@plugin.should_receive( :require ).at_least(6).times.and_return {|path|
				raise ScriptError, "error while parsing #{path}"
			}

			expect {
				@plugin.create('portable')
			}.to raise_error( ScriptError, /error while parsing/ )
		end
	end


	context "derivative of an extended class" do

		it "knows what type of factory loads it" do
			TestingPlugin.factory_type.should == '@plugin'
		end

		it "raises a FactoryError if it can't figure out what type of factory loads it" do
			TestingPlugin.stub!( :ancestors ).and_return( [] )
			expect {
				TestingPlugin.factory_type
			}.to raise_error( FactoryError, /couldn't find factory base/i )
		end
	end


	context "derivative of an extended class that isn't named <Something>@plugin" do

		it "is still creatable via its full name" do
			@plugin.create( 'blacksheep' ).should be_an_instance_of( BlackSheep )
		end

	end


	context "derivative of an extended class in another namespace" do

		it "is still creatable via its derivative name" do
			@plugin.create( 'loadable' ).should be_an_instance_of( Test::LoadablePlugin )
		end

	end

end

