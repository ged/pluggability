# -*- ruby -*-
#encoding: utf-8

require 'loggability' unless defined?( Loggability )

# The Pluggability module
module Pluggability
	extend Loggability

	# Loggability API -- Set up a logger.
	log_as :pluggability


	# Library version
	VERSION = '0.4.2'


	# An exception class for Pluggability specific errors.
	class PluginError < RuntimeError; end
	FactoryError = PluginError


	### Add the @derivatives instance variable to including classes.
	def self::extend_object( obj )
		obj.instance_variable_set( :@plugin_prefixes, [] )
		obj.instance_variable_set( :@plugin_exclusions, [] )
		obj.instance_variable_set( :@derivatives, {} )

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
	alias factory_type plugin_type


	### Inheritance callback -- Register subclasses in the derivatives hash
	### so that ::create knows about them.
	def inherited( subclass )
		plugin_class = Pluggability.plugin_base_class( subclass )

		Pluggability.logger.debug "%p inherited by %p" % [ plugin_class, subclass ]
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

		# Add a name attribute to it
		class << subclass
			attr_reader :plugin_name
		end
		subclass.instance_variable_set( :@plugin_name, keys.last )

		super
	end


	### Return all variants of the name of the given +subclass+ that can be
	### used to load it.
	def make_derivative_names( subclass )
		keys = []

		simple_name = subclass.name.sub( /^.*::/i, '' ).sub( /\W+$/, '' )
		keys << simple_name << simple_name.downcase
		keys << simple_name.gsub( /([a-z])([A-Z])/, "\\1_\\2" ).downcase

		# Handle class names like 'FooBar' for 'Bar' factories.
		Pluggability.log.debug "Inherited %p for %p-type plugins" % [ subclass, self.plugin_type ]
		if subclass.name.match( /(?:.*::)?(\w+)(?:#{self.plugin_type})/i )
			keys << Regexp.last_match[1].downcase
		else
			keys << subclass.name.sub( /.*::/, '' ).downcase
		end

		return keys
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
	def create( class_name, *args, &block )
		subclass = get_subclass( class_name )

		begin
			return subclass.new( *args, &block )
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
			candidates = Gem.find_latest_files( glob )
			Pluggability.log.debug "  found %d matching files" % [ candidates.length ]
			next if candidates.empty?

			candidates.each do |path|
				next if self.is_excluded_path?( path )
				require( path )
			end
		end

		return self.derivative_classes
	end


	### Calculates an appropriate filename for the derived class using the
	### name of the base class and tries to load it via <tt>require</tt>. If
	### the including class responds to a method named
	### <tt>derivativeDirs</tt>, its return value (either a String, or an
	### array of Strings) is added to the list of prefix directories to try
	### when attempting to require a modules. Eg., if
	### <tt>class.derivativeDirs</tt> returns <tt>['foo','bar']</tt> the
	### require line is tried with both <tt>'foo/'</tt> and <tt>'bar/'</tt>
	### prepended to it.
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
	### #plugin_prefixes that have been set.
	def require_derivative( mod_name )

		subdirs = self.plugin_prefixes
		subdirs << '' if subdirs.empty?
		Pluggability.log.debug "Subdirs are: %p" % [subdirs]
		fatals = []
		tries  = []

		# Iterate over the subdirs until we successfully require a
		# module.
		subdirs.map( &:strip ).each do |subdir|
			self.make_require_path( mod_name, subdir ).each do |path|
				next if self.is_excluded_path?( path )

				Pluggability.logger.debug "Trying #{path}..."
				tries << path

				# Try to require the module, saving errors and jumping
				# out of the catch block on success.
				begin
					require( path.untaint )
				rescue LoadError => err
					Pluggability.log.debug "No module at '%s', trying the next alternative: '%s'" %
						[ path, err.message ]
				rescue Exception => err
					fatals << err
					Pluggability.log.error "Found '#{path}', but encountered an error: %s\n\t%s" %
						[ err.message, err.backtrace.join("\n\t") ]
				else
					Pluggability.log.info "Loaded '#{path}' without error."
					return path
				end
			end
		end

		Pluggability.logger.debug "fatals = %p" % [ fatals ]

		# Re-raise is there was a file found, but it didn't load for
		# some reason.
		if fatals.empty?
			errmsg = "Couldn't find a %s named '%s': tried %p" % [
				self.plugin_type,
				mod_name,
				tries
			  ]
			Pluggability.log.error( errmsg )
			raise PluginError, errmsg
		else
			Pluggability.log.debug "Re-raising first fatal error"
			Kernel.raise( fatals.first )
		end
	end


	### Make a list of permutations of the given +modname+ for the given
	### +subdir+. Called on a +DataDriver+ class with the arguments 'Socket' and
	### 'drivers', returns:
	###   ["drivers/socketdatadriver", "drivers/socketDataDriver",
	###    "drivers/SocketDataDriver", "drivers/socket", "drivers/Socket"]
	def make_require_path( modname, subdir )
		path = []
		myname = self.plugin_type

		# Make permutations of the two parts
		path << modname
		path << modname.downcase
		path << modname			       + myname
		path << modname.downcase       + myname
		path << modname.downcase       + myname.downcase
		path << modname			 + '_' + myname
		path << modname.downcase + '_' + myname
		path << modname.downcase + '_' + myname.downcase

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

