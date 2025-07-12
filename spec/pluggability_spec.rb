#!/usr/bin/env ruby

require_relative 'helpers'

require 'pluggability'
require 'loggability'

Loggability.level = :debug

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
class Carbon14Robot < Plugin; end
module Test
	class LoadablePlugin < Plugin; end
end
class KeywordTest < Plugin
	def initialize( **kwargs)
		@kwargs = kwargs
	end
	attr_reader :kwargs
end

class SubSubPlugin < SubPlugin; end


#
# Examples
#
RSpec.describe Pluggability do

	before( :each ) do
		Plugin.plugin_exclusions = []
		allow( File ).to receive( :file? ).and_return( true )
	end


	it "allows extended objects to declare one or more prefixes to use when requiring derviatives" do
		expect( Plugin.plugin_prefixes ).to eq( ['plugins', 'plugins/private'] )
	end


	context "-extended class" do

		it "knows about all of its derivatives" do
			expect( Plugin.derivatives.keys ).
				to include( 'sub', 'subplugin', 'SubPlugin', SubPlugin )
		end


		it "returns derivatives directly if they're already loaded" do
			class AlreadyLoadedPlugin < Plugin; end
			expect( Kernel ).to_not receive( :require )
			expect( Plugin.create('alreadyloaded') ).to be_an_instance_of( AlreadyLoadedPlugin )
			expect( Plugin.create('AlreadyLoaded') ).to be_an_instance_of( AlreadyLoadedPlugin )
			expect( Plugin.create('AlreadyLoadedPlugin') ).to be_an_instance_of( AlreadyLoadedPlugin )
			expect( Plugin.create(AlreadyLoadedPlugin) ).to be_an_instance_of( AlreadyLoadedPlugin )
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

			expect( exception.backtrace.first ).to match(/#{__FILE__}/)
		end


		it "will refuse to create an object other than one of its derivatives" do
			class Doppelgaenger; end
			expect {
				Plugin.create(Doppelgaenger)
			}.to raise_error( ArgumentError, /is not a descendent of/ )
		end


		it "will load new plugins from the require path if they're not loaded yet" do
			loaded_class = nil

			expect( Gem ).to receive( :find_latest_files ).
				at_least( :once ).
				and_return( ['/some/path/to/plugins/dazzle.rb'] )
			expect( Kernel ).to receive( :require ).with( '/some/path/to/plugins/dazzle.rb' ) do |*args|
				loaded_class = Class.new( Plugin ) do
					set_temporary_name 'Plugin::Dazzle (testing class)'
				end
				true
			end

			expect( Plugin.create('dazzle') ).to be_an_instance_of( loaded_class )
		end


		it "will load new plugins from the require path if given a camel-cased class name" do
			loaded_class = nil

			expect( Gem ).to receive( :find_latest_files ).
				at_least( :once ).
				and_return( ['/some/path/to/plugins/razzle_dazzle.rb'] )
			expect( Kernel ).to receive( :require ) do |require_path|
				expect( require_path ).to eq( '/some/path/to/plugins/razzle_dazzle.rb' )

				loaded_class = Class.new( Plugin ) do
					set_temporary_name 'Plugin::RazzleDazzle (testing class)'
				end

				true
			end

			expect( Plugin.create(:RazzleDazzle) ).to be_an_instance_of( loaded_class )
		end


		it "will output a sensible description of what it tried to load if requiring a " +
			"derivative fails" do

			# at least 6 -> 3 variants * 2 paths
			expect( Gem ).to receive( :find_latest_files ).at_least( 4 ).times.
				and_return( [] )

			expect {
				Plugin.create('scintillating')
			}.to raise_error( Pluggability::PluginError, /couldn't find a \S+ named \S+.*tried \[/i )
		end


		it "will output a sensible description when a require succeeds, but it loads something unintended" do
			expect( Gem ).to receive( :find_latest_files ).
				at_least( :once ).
				and_return( ['/some/path/to/corruscating.rb'] )
			expect( Kernel ).to receive( :require ).
				with( '/some/path/to/corruscating.rb' ).
				and_return( true )

			expect {
				Plugin.create('corruscating')
			}.to raise_error( Pluggability::PluginError, /Require of '\S+' succeeded, but didn't load a Plugin/i )
		end


		it "doesn't rescue LoadErrors raised when loading the plugin" do
			expect( Gem ).to receive( :find_latest_files ).
				at_least( :once ).
				and_return( ['/some/path/to/portable.rb'] )
			expect( Kernel ).to receive( :require ).
				with( '/some/path/to/portable.rb' ).
				and_raise( ScriptError.new("error while parsing path") )

			expect {
				Plugin.create( 'portable' )
			}.to raise_error( ScriptError, /error while parsing/ )
		end


		it "ignores directories when finding derivatives" do
			expect( Gem ).to receive( :find_latest_files ).
				at_least( :once ).
				and_return( ['/some/path/to/portable', '/some/path/to/portable.rb'] )
			expect( File ).to receive( :file? ).and_return( false )

			expect( Kernel ).to_not receive( :require ).with( '/some/path/to/portable' )
			expect( Kernel ).to receive( :require ).
				with( '/some/path/to/portable.rb' ).
				and_return( true )

			expect {
				Plugin.create( 'portable' )
			}.to raise_error( Pluggability::PluginError, /Require of '\S+' succeeded, but didn't load a Plugin/i )
		end


		it "can preload all of its derivatives" do
			expect( Gem ).to receive( :find_latest_files ).with( 'plugins/*.rb' ).
				and_return([ 'plugins/first.rb' ])
			expect( Gem ).to receive( :find_latest_files ).with( 'plugins/private/*.rb' ).
				and_return([ 'plugins/private/second.rb', 'plugins/private/third.rb' ])

			expect( Kernel ).to receive( :require ).with( 'plugins/first.rb' ).
				and_return( true )
			expect( Kernel ).to receive( :require ).with( 'plugins/private/second.rb' ).
				and_return( true )
			expect( Kernel ).to receive( :require ).with( 'plugins/private/third.rb' ).
				and_return( true )

			Plugin.load_all
		end


		it "doesn't preload derivatives whose path matches a Regexp exclusion" do
			expect( Gem ).to receive( :find_latest_files ).with( 'plugins/*.rb' ).
				and_return([ '/path/to/plugins/first.rb' ])
			expect( Gem ).to receive( :find_latest_files ).with( 'plugins/private/*.rb' ).
				and_return([ '/path/to/plugins/private/second.rb', '/path/to/plugins/private/third.rb' ])

			expect( Kernel ).to receive( :require ).with( '/path/to/plugins/first.rb' ).
				and_return( true )
			expect( Kernel ).to_not receive( :require ).with( '/path/to/plugins/private/second.rb' )
			expect( Kernel ).to_not receive( :require ).with( '/path/to/plugins/private/third.rb' )

			Plugin.plugin_exclusions( %r{/private} )
			Plugin.load_all
		end


		it "doesn't preload derivatives whose path matches a glob String exclusion" do
			expect( Gem ).to receive( :find_latest_files ).with( 'plugins/*.rb' ).
				and_return([ 'plugins/first.rb' ])
			expect( Gem ).to receive( :find_latest_files ).with( 'plugins/private/*.rb' ).
				and_return([ 'plugins/private/second.rb', 'plugins/private/third.rb' ])

			expect( Kernel ).to receive( :require ).with( 'plugins/first.rb' ).
				and_return( true )
			expect( Kernel ).to receive( :require ).with( 'plugins/private/second.rb' ).
				and_return( true )
			expect( Kernel ).to_not receive( :require ).with( 'plugins/private/third.rb' )

			Plugin.plugin_exclusions( '**/third.rb' )
			Plugin.load_all
		end


		it "passes keyword arguments when creating derivatives" do
			result = Plugin.create( KeywordTest, foo: :bar, baz: 2 )
			expect( result.kwargs ).to eq({ foo: :bar, baz: 2 })
		end

	end


	context "derivative of an extended class" do

		it "knows what type of plugin loads it" do
			expect( TestingPlugin.plugin_type ).to eq( 'Plugin' )
		end


		it "raises a PluginError if it can't figure out what type of factory loads it" do
			allow( TestingPlugin ).to receive( :ancestors ).and_return( [] )
			expect {
				TestingPlugin.plugin_type
			}.to raise_error( Pluggability::PluginError, /couldn't find plugin base/i )
		end


		it "knows what the simplest version of its plugin name is" do
			expect( TestingPlugin.plugin_name ).to eq( 'testing' )
		end
	end


	context "derivative of an extended class that isn't named <Something>Plugin" do

		it "is still creatable via its full name" do
			expect( Plugin.create('blacksheep') ).to be_an_instance_of( BlackSheep )
		end


		it "is loadable via its underbarred name" do
			expect( Plugin.create('black_sheep') ).to be_an_instance_of( BlackSheep )
		end


		it "works for classes with numbers in them too" do
			expect( Plugin.create('carbon14_robot') ).to be_an_instance_of( Carbon14Robot )
		end


		it "knows what the simplest version of its plugin name is" do
			expect( BlackSheep.plugin_name ).to eq( 'black_sheep' )
		end
	end


	context "derivative of an extended class in another namespace" do

		it "is still creatable via its derivative name" do
			expect( Plugin.create('loadable') ).to be_an_instance_of( Test::LoadablePlugin )
		end


		it "still knows what the simplest version of its plugin name is" do
			expect( Test::LoadablePlugin.plugin_name ).to eq( 'loadable' )
		end

	end


	context "subclass of a derivative" do

		it "is still registered with the base class" do
			expect( Plugin.derivatives['subsub'] ).to eq( SubSubPlugin )
		end


		it "still knows what the simplest version of its plugin name is" do
			expect( SubSubPlugin.plugin_name ).to eq( 'subsub' )
		end

	end

end

