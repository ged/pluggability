#!/usr/bin/env ruby -w

require 'loggability' unless defined?( Loggability )


# The Pluggability module
module Pluggability
	extend Loggability

	# Loggability API -- Set up a logger.
	log_as :pluggability


	# Library version
	VERSION = '0.0.1'


	### An exception class for Pluggability specific errors.
	class FactoryError < RuntimeError; end


	### Add the @derivatives instance variable to including classes.
	def self::extend_object( obj )
		obj.instance_variable_set( :@plugin_prefixes, [] )
		obj.instance_variable_set( :@derivatives, {} )
		super
	end


	#############################################################
	###	M I X I N   M E T H O D S
	#############################################################

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


	### Return the Hash of derivative classes, keyed by various versions of
	### the class name.
	def derivatives
		ancestors.each do |klass|
			if klass.instance_variables.include?( :@derivatives ) ||
			   klass.instance_variables.include?( "@derivatives" )
				return klass.instance_variable_get( :@derivatives )
			end
		end
	end


	### Returns the type name used when searching for a derivative.
	def factory_type
		base = nil
		self.ancestors.each do |klass|
			if klass.instance_variables.include?( :@derivatives ) ||
				klass.instance_variables.include?( "@derivatives" )
				base = klass
				break
			end
		end

		raise FactoryError, "Couldn't find factory base for #{self.name}" if
			base.nil?

		if base.name =~ /^.*::(.*)/
			return $1
		else
			return base.name
		end
	end


	### Inheritance callback -- Register subclasses in the derivatives hash
	### so that ::create knows about them.
	def inherited( subclass )
		keys = [ subclass ]

		# If it's not an anonymous class, make some keys out of variants of its name
		if subclass.name
			simple_name = subclass.name.sub( /#<Class:0x[[:xdigit:]]+>::/i, '' )
			keys << simple_name << simple_name.downcase

			# Handle class names like 'FooBar' for 'Bar' factories.
			Pluggability.log.debug "Inherited %p for %p-type plugins" % [ subclass, self.factory_type ]
			if subclass.name.match( /(?:.*::)?(\w+)(?:#{self.factory_type})/i )
				keys << Regexp.last_match[1].downcase
			else
				keys << subclass.name.sub( /.*::/, '' ).downcase
			end
		else
			Pluggability.log.debug "  no name-based variants for anonymous subclass %p" % [ subclass ]
		end

		keys.compact.uniq.each do |key|
			Pluggability.log.info "Registering %s derivative of %s as %p" %
				[ subclass.name, self.name, key ]
			self.derivatives[ key ] = subclass
		end

		super
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
				raise FactoryError,
					"load_derivative(%s) added something other than a class "\
					"to the registry for %s: %p" %
					[ class_name, self.name, subclass ]
			end
		end

		return self.derivatives[ class_name.downcase ]
	end


	### Find and load all derivatives of this class, using plugin_prefixes if any
	### are defined, or a pattern derived from the #factory_type if not. Returns
	### an array of all derivative classes. Load failures are logged but otherwise
	### ignored.
	def load_all
		patterns = []
		prefixes = self.plugin_prefixes

		if prefixes && !prefixes.empty?
			Pluggability.log.debug "Using plugin prefixes (%p) to build load patterns." % [ prefixes ]
			prefixes.each do |prefix|
				patterns << "#{prefix}/*.rb"
			end
		else
			# Use all but the last pattern, which will just be '*.rb'
			Pluggability.log.debug "Using factory type (%p) to build load patterns." %
				[ self.factory_type ]
			patterns += self.make_require_path( '*', '' )[0..-2].
				map {|f| f + '.rb' }
		end

		patterns.each do |glob|
			Pluggability.log.debug "  finding derivatives matching pattern %p" % [ glob ]
			candidates = Gem.find_files( glob )
			Pluggability.log.debug "  found %d matching files" % [ candidates.length ]
			next if candidates.empty?

			candidates.each {|path| require(path) }
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
				self.factory_type,
				class_name.downcase,
			]
			Pluggability.log.error( errmsg )
			raise FactoryError, errmsg, caller(3)
		end
	end


	### Build and return the unique part of the given <tt>class_name</tt>
	### either by stripping leading namespaces if the name already has the
	### name of the factory type in it (eg., 'My::FooService' for Service,
	### or by appending the factory type if it doesn't.
	def get_module_name( class_name )
		if class_name =~ /\w+#{self.factory_type}/
			mod_name = class_name.sub( /(?:.*::)?(\w+)(?:#{self.factory_type})/, "\\1" )
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
				self.factory_type,
				mod_name,
				tries
			  ]
			Pluggability.log.error( errmsg )
			raise FactoryError, errmsg
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
		myname = self.factory_type

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

