# -*- ruby -*-

require 'loggability' unless defined?( Loggability )


# The Pluggability module
module Pluggability
	extend Loggability

	# Loggability API -- Set up a logger.
	log_as :pluggability


	# Library version
	VERSION = '0.10.0'


	# An exception class for Pluggability specific errors.
	class PluginError < RuntimeError; end
	FactoryError = PluginError


	module StringRefinements
		refine( String ) do

			def uncamelcase
				return self.gsub( /([a-z0-9])([A-Z])/, "\\1_\\2" )
			end

		end
	end
	using StringRefinements


	### Add the @derivatives instance variable to including classes.
	def self::extend_object( obj )
		obj.instance_variable_set( :@plugin_prefixes, [] )
		obj.instance_variable_set( :@plugin_exclusions, [] )
		obj.instance_variable_set( :@derivatives, {} )

		obj.singleton_class.attr_accessor( :plugin_name )

		Pluggability.pluggable_classes << obj

		super
	end


	##
	# The Array of all classes that have added Pluggability
	@pluggable_classes = []
	class << self; attr_reader :pluggable_classes; end


	### Return the ancestor of +subclass+ that has Pluggability.
	def self::plugin_base_class( subclass )
		return subclass.ancestors.find do |klass|
			Pluggability.pluggable_classes.include?( klass )
		end
	end


	#############################################################
	###	M I X I N   M E T H O D S
	#############################################################

	### Return the Hash of derivative classes, keyed by various versions of
	### the class name.
	attr_reader :derivatives


	### Get/set the prefixes that will be used when searching for particular plugins
	### for the calling Class.
	def plugin_prefixes( *args )
		@plugin_prefixes.replace( args ) if !args.empty?
		return @plugin_prefixes
	end


	### Set the prefixes that will be used when searching for particular plugins
	### for the calling Class.
	def plugin_prefixes=( args )
		@plugin_prefixes = Array( args )
	end


	### Get/set patterns which cause files in a plugin path to not be loaded. Typical
	### use case is to exclude test/spec directories:
	###
	###     MyFactoryType.plugin_exclude( 'spec/**' )
	###
	def plugin_exclusions( *exclusions )
		@plugin_exclusions.replace( exclusions ) if !exclusions.empty?
		return @plugin_exclusions
	end


	### Set the plugin exclusion patterns which cause files in a plugin path to not
	### be loaded.
	def plugin_exclusions=( args )
		@plugin_exclusions = Array( args )
	end


	### Returns +true+ if any of the #plugin_exclusions match the specified
	### +path.
	def is_excluded_path?( path )
		rval = self.plugin_exclusions.find do |exclusion|
			case exclusion
			when Regexp
				path =~ exclusion
			when String
				flags = 0
				flags &= File::FNM_EXTGLOB if defined?( File::FNM_EXTGLOB )
				File.fnmatch( exclusion, path, flags )
			else
				Pluggability.log.warn "Don't know how to apply exclusion: %p" % [ exclusion ]
				false
			end
		end

		if rval
			Pluggability.log.debug "load path %p is excluded by %p" % [ path, rval ]
			return true
		else
			return false
		end
	end


	### Returns the type name used when searching for a derivative.
	def plugin_type
		base = Pluggability.plugin_base_class( self ) or
			raise PluginError, "Couldn't find plugin base for #{self.name}"

		if base.name =~ /^.*::(.*)/
			return $1
		else
			return base.name
		end
	end
	alias_method :factory_type, :plugin_type


	### Inheritance callback -- Register subclasses in the derivatives hash
	### so that ::create knows about them.
	def inherited( subclass )
		Pluggability.log.debug "  %p inherited by %p" % [ self, subclass ]
		self.register_plugin_type( subclass )
		super
	end


	### Override Module#set_temporary_name so +new_name+ can be used to derive the
	### plugin name. Note that this does *not* detect if you later assign the
	### anonymous class to a constant and thus clear its temporary name.
	def set_temporary_name( new_name )
		super
		self.register_plugin_type( self )
	end


	### Register the given +subclass+ as a plugin type of the receiving Pluggable class.
	def register_plugin_type( subclass )
		plugin_class = Pluggability.plugin_base_class( subclass )
		keys = [ subclass ]

		# If it's not an anonymous class, make some keys out of variants of its name
		if subclass.name
			keys += plugin_class.make_derivative_names( subclass )
		else
			Pluggability.log.debug "  no name-based variants for anonymous subclass %p" % [ subclass ]
		end

		keys.compact!
		keys.uniq!

		# Register it under each of its name variants
		keys.each do |key|
			Pluggability.log.debug "Registering %s derivative of %s as %p" %
				[ subclass.name, plugin_class.name, key ]
			plugin_class.derivatives[ key ] = subclass
		end

		Pluggability.log.debug "Setting plugin name of %p to %p" % [ subclass, keys.last ]
		subclass.plugin_name = keys.last
	end


	### Return all variants of the name of the given +subclass+ that can be
	### used to load it.
	def make_derivative_names( subclass )
		keys = []

		# Order is important here, as the last non-nil one becomes the plugin_name.
		simple_name = subclass.name.sub( /\A.*::/, '' ).sub( /\A(\w+).*/, '\\1' )
		keys << simple_name << simple_name.downcase
		keys << simple_name.uncamelcase.downcase

		simpler_name = simple_name.sub( /(?:#{self.plugin_type})\z/, '' )
		keys << simpler_name << simpler_name.downcase
		keys << simpler_name.uncamelcase.downcase

		return keys.uniq
	end


	### Returns an Array of registered derivatives
	def derivative_classes
		self.derivatives.values.uniq
	end


	### Given the <tt>class_name</tt> of the class to instantiate, and other
	### arguments bound for the constructor of the new object, this method
	### loads the derivative class if it is not loaded already (raising a
	### LoadError if an appropriately-named file cannot be found), and
	### instantiates it with the given <tt>args</tt>. The <tt>class_name</tt>
	### may be the the fully qualified name of the class, the class object
	### itself, or the unique part of the class name. The following examples
	### would all try to load and instantiate a class called "FooListener"
	### if Listener included Factory
	###   obj = Listener.create( 'FooListener' )
	###   obj = Listener.create( FooListener )
	###   obj = Listener.create( 'Foo' )
	def create( class_name, *args, **keyword_args, &block )
		subclass = get_subclass( class_name )

		begin
			return subclass.new( *args, **keyword_args, &block )
		rescue => err
			nicetrace = err.backtrace.reject {|frame| /#{__FILE__}/ =~ frame}
			msg = "When creating '#{class_name}': " + err.message
			Kernel.raise( err, msg, nicetrace )
		end
	end


	### Given a <tt>class_name</tt> like that of the first argument to
	### #create, attempt to load the corresponding class if it is not
	### already loaded and return the class object.
	def get_subclass( class_name )
		return self if ( self.name == class_name || class_name == '' )
		if class_name.is_a?( Class )
			return class_name if class_name <= self
			raise ArgumentError, "%s is not a descendent of %s" % [class_name, self]
		end

		class_name = class_name.to_s

		# If the derivatives hash doesn't already contain the class, try to load it
		unless self.derivatives.has_key?( class_name.downcase )
			self.load_derivative( class_name )

			subclass = self.derivatives[ class_name.downcase ]
			unless subclass.is_a?( Class )
				raise PluginError,
					"load_derivative(%s) added something other than a class "\
					"to the registry for %s: %p" %
					[ class_name, self.name, subclass ]
			end
		end

		return self.derivatives[ class_name.downcase ]
	end


	### Find and load all derivatives of this class, using plugin_prefixes if any
	### are defined, or a pattern derived from the #plugin_type if not. Returns
	### an array of all derivative classes. Load failures are logged but otherwise
	### ignored.
	def load_all
		Pluggability.log.debug "Loading all %p derivatives." % [ self ]
		patterns = []
		prefixes = self.plugin_prefixes

		if prefixes && !prefixes.empty?
			Pluggability.log.debug "Using plugin prefixes (%p) to build load patterns." % [ prefixes ]
			prefixes.each do |prefix|
				patterns << "#{prefix}/*.rb"
			end
		else
			# Use all but the last pattern, which will just be '*.rb'
			Pluggability.log.debug "Using plugin type (%p) to build load patterns." %
				[ self.plugin_type ]
			patterns += self.make_require_path( '*', '' )[0..-2].
				map {|f| f + '.rb' }
		end

		patterns.each do |glob|
			Pluggability.log.debug "  finding derivatives matching pattern %p" % [ glob ]
			candidates = if Gem.respond_to?( :find_latest_files )
					Gem.find_latest_files( glob )
				else
					Gem.find_files( glob )
				end

			Pluggability.log.debug "  found %d matching files" % [ candidates.length ]
			next if candidates.empty?

			candidates.each do |path|
				next if self.is_excluded_path?( path )
				Kernel.require( path )
			end
		end

		return self.derivative_classes
	end


	### Calculates an appropriate filename for the derived class using the name of
	### the base class and tries to load it via <tt>load</tt>. If the including
	### class responds to a method named <tt>plugin_prefixes</tt>, its return value
	### (either a String, or an array of Strings) is added to the list of prefix
	### directories to try when attempting to load modules. Eg., if
	### <tt>class.plugin_prefixes</tt> returns <tt>['foo','bar']</tt> the require
	### line is tried with both <tt>'foo/'</tt> and <tt>'bar/'</tt> prepended to it.
	def load_derivative( class_name )
		Pluggability.log.debug "Loading derivative #{class_name}"

		# Get the unique part of the derived class name and try to
		# load it from one of the derivative subdirs, if there are
		# any.
		mod_name = self.get_module_name( class_name )
		result = self.require_derivative( mod_name )

		# Check to see if the specified listener is now loaded. If it
		# is not, raise an error to that effect.
		unless self.derivatives[ class_name.downcase ]
			errmsg = "Require of '%s' succeeded, but didn't load a %s named '%s' for some reason." % [
				result,
				self.plugin_type,
				class_name.downcase,
			]
			Pluggability.log.error( errmsg )
			raise PluginError, errmsg, caller(3)
		end
	end


	### Build and return the unique part of the given <tt>class_name</tt>
	### either by stripping leading namespaces if the name already has the
	### name of the plugin type in it (eg., 'My::FooService' for Service,
	### or by appending the plugin type if it doesn't.
	def get_module_name( class_name )
		if class_name =~ /\w+#{self.plugin_type}/
			mod_name = class_name.sub( /(?:.*::)?(\w+)(?:#{self.plugin_type})/, "\\1" )
		else
			mod_name = class_name
		end

		return mod_name
	end


	### Search for the module with the specified <tt>mod_name</tt>, using any
	### #plugin_prefixes that have been set. Return the path that was required.
	def require_derivative( mod_name )
		plugin_path = self.find_plugin_path( mod_name )
		unless plugin_path
			errmsg = "Couldn't find a %s named '%s': tried %p" % [
				self.plugin_type,
				mod_name,
				self.plugin_path_candidates( mod_name )
			]
			Pluggability.log.error( errmsg )
			raise Pluggability::PluginError, errmsg
		end

		Kernel.require( plugin_path )

		return plugin_path
	end


	### Search for the file that corresponds to +mod_name+ using the plugin prefixes
	### and current Gem load path and return the path to the first candidate that
	### exists.
	def find_plugin_path( mod_name )
		candidates = self.plugin_path_candidates( mod_name )
		Pluggability.log.debug "Candidates for %p are: %p" % [ mod_name, candidates ]

		candidate_paths = candidates.
			flat_map {|path| Gem.find_latest_files( path ) }.
			uniq.
			reject {|path| self.is_excluded_path?( path ) || ! File.file?(path) }
		Pluggability.log.debug "Valid candidates in the current gemset: %p" % [ candidate_paths ]

		return candidate_paths.first
	end


	### Return an Array of all the filenames a plugin of the given +mod_name+ might
	### map to given the current plugin_prefixes.
	def plugin_path_candidates( mod_name )
		prefixes = self.plugin_prefixes
		prefixes << '' if prefixes.empty?

		return prefixes.flat_map {|pre| self.make_require_path(mod_name, pre) }.uniq
	end


	### Make a list of permutations of the given +modname+ for the given
	### +subdir+. Called on a +DataDriver+ class with the arguments 'Socket' and
	### 'drivers', returns:
	###   ["drivers/socketdatadriver", "drivers/socketDataDriver",
	###    "drivers/SocketDataDriver", "drivers/socket", "drivers/Socket"]
	def make_require_path( modname, subdir )
		path = []
		myname = self.plugin_type.uncamelcase.downcase
		modname = modname.uncamelcase.downcase

		# Make permutations of the two parts
		path << modname
		path << modname + '_' + myname

		# If a non-empty subdir was given, prepend it to all the items in the
		# path
		unless subdir.nil? or subdir.empty?
			path.collect! {|m| File.join(subdir, m)}
		end

		Pluggability.log.debug "Path is: #{path.uniq.reverse.inspect}..."
		return path.uniq.reverse
	end

end # module Pluggability


# Backward-compatibility alias
FactoryError = Pluggability::PluginError unless defined?( FactoryError )

