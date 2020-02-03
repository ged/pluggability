# pluggability

home
: https://hg.sr.ht/~ged/pluggability

docs
: https://deveiate.org/code/pluggability

github
: https://github.com/ged/pluggability


## Description

Pluggability is a toolkit for creating plugins.

It provides a mixin that extends your class with methods to load and instantiate its subclasses by name. So instead of:

    require 'acme/adapter/png'
    png_adapter = Acme::Adapter::PNG.new( 'file.png' )
  
you can do:

    require 'acme/adapter'
    png_adapter = Acme::Adapter.create( :png, 'file.png' )

A full example of where this might be useful is in a program which generates
output with a 'driver' object, which provides a unified interface but generates
different kinds of output.

First the abstract base class, which is extended with Pluggability:

    # in mygem/driver.rb:
    require 'pluggability'
    require 'mygem' unless defined?( MyGem )
    
    class MyGem::Driver
        extend Pluggability
        plugin_prefixes "mygem/drivers"
    end

We can have one driver that outputs PDF documents:

    # mygem/drivers/pdf.rb:
    require 'mygem/driver' unless defined?( MyGem::Driver )
    
    class MyGem::Driver::PDF < Driver
        ...implementation...
    end

and another that outputs plain ascii text:

    #mygem/drivers/ascii.rb:
    require 'mygem/driver' unless defined?( MyGem::Driver )
    
    class MyGem::Driver::ASCII < Driver
        ...implementation...
    end

Now the driver is configurable by the end-user, who can just set
it by its short name:

    require 'mygem'
    
    config[:driver_type] #=> "pdf"
    driver = MyGem::Driver.create( config[:driver_type] )
    driver.class #=> MyGem::Driver::PDF

    # You can also pass arguments to the constructor, too:
    ascii_driver = MyGem::Driver.create( :ascii, :columns => 80 )


### How Plugins Are Loaded

The `create` class method added to your class by Pluggability searches for your
module using several different strategies. It tries various permutations of the
base class's name in combination with the derivative requested. For example,
assume we want to make a `LogReader` base class, and then use plugins to define
readers for different log formats:

    require 'pluggability'
    
    class LogReader
        extend Pluggability

        def read_from_file( path ); end
    end

When you attempt to load the 'apache' logreader class like so:

    LogReader.create( 'apache' )

Pluggability searches for modules with the following names:

    ApacheLogReader
    apachelogreader
    apache_log_reader
    apache
 
Obviously the last one might load something other than what is intended, so you
can also tell Pluggability that plugins should be loaded from a subdirectory by
declaring one or more `plugin_prefixes` in the base class. Each prefix will be
tried (in the order they're declared) when searching for a subclass:

    class LogReader
        extend Pluggability
        plugin_prefixes 'drivers'
    end

This will change the list that is required to:

    drivers/apache_logreader
    drivers/apache_LogReader
    drivers/apachelogreader
    drivers/apacheLogReader
    drivers/apache

If you specify more than one subdirectory, each of them will be tried in
turn:

    class LogReader
        extend Pluggability
        plugin_prefixes 'drivers', 'logreader'
    end

will change the search to include:

    'drivers/apachelogreader'
    'drivers/apache_logreader'
    'drivers/apacheLogReader'
    'drivers/apache_LogReader'
    'drivers/ApacheLogReader'
    'drivers/Apache_LogReader'
    'drivers/apache'
    'drivers/Apache'
    'logreader/apachelogreader'
    'logreader/apache_logreader'
    'logreader/apacheLogReader'
    'logreader/apache_LogReader'
    'logreader/ApacheLogReader'
    'logreader/Apache_LogReader'
    'logreader/apache'
    'logreader/Apache'

If the plugin is not found, a Pluggability::PluginError is raised, and the
message will list all the permutations that were tried.


### Preloaded Plugins

Sometimes you don't want to wait for plugins to be loaded on demand. For that
case, Pluggability provides the Pluggability#load_all method. This will find
all possible matches for plugin files and load them, returning an Array of all
the loaded classes:

    class Template::Tag
        extend Pluggability
        plugin_prefixes 'tag'
    end

    tag_classes = Template::Tag.load_all


### Excluding Some Files

You can also prevent some files from being automatically loaded by either
Pluggability#create or Pluggability#load_all by setting one or more exclusion
patterns:

    LogReader.plugin_exclusions 'spec/*', %r{/test/}

The patterns can either be Regexps or glob Strings.


### Logging

If you need a little more insight into what's going on, Pluggability uses the
[Loggability](https://rubygems.org/gems/loggability) library. Just set the log
level to 'debug' and it'll explain what's going on:

    require 'pluggability'
    require 'loggability'
    
    class LogReader
        extend Pluggability
    end
    
    # Global level
    Loggability.level = :debug

    # Or just Pluggability's level:
    Pluggability.logger.level = :debug
    
    LogReader.create( 'ringbuffer' )

this might generate a log that looks (something) like:

    [...] debug {} -- Loading derivative ringbuffer
    [...] debug {} -- Subdirs are: [""]
    [...] debug {} -- Path is: ["ringbuffer_logreader", "ringbuffer_LogReader",
      "ringbufferlogreader", "ringbufferLogReader", "ringbuffer"]...
    [...] debug {} -- Trying ringbuffer_logreader...
    [...] debug {} -- No module at 'ringbuffer_logreader', trying the next alternative:
      'cannot load such file -- ringbuffer_logreader'
    [...] debug {} -- Trying ringbuffer_LogReader...
    [...] debug {} -- No module at 'ringbuffer_LogReader', trying the next alternative:
      'cannot load such file -- ringbuffer_LogReader'
    [...] debug {} -- Trying ringbufferlogreader...
    [...] debug {} -- No module at 'ringbufferlogreader', trying the next alternative:
      'cannot load such file -- ringbufferlogreader'
    [...] debug {} -- Trying ringbufferLogReader...
    [...] debug {} -- No module at 'ringbufferLogReader', trying the next alternative:
      'cannot load such file -- ringbufferLogReader'
    [...] debug {} -- Trying ringbuffer...
    [...] debug {} -- No module at 'ringbuffer', trying the next alternative:
      'cannot load such file -- ringbuffer'
    [...] debug {} -- fatals = []
    [...] error {} -- Couldn't find a LogReader named 'ringbuffer': tried 
      ["ringbuffer_logreader", "ringbuffer_LogReader", 
      "ringbufferlogreader", "ringbufferLogReader", "ringbuffer"]


## Installation

    gem install pluggability


## Contributing

You can check out the current development source with Mercurial via its
[Mercurial repo](https://bitbucket.org/ged/pluggability). Or if you prefer Git,
via [its Github mirror](https://github.com/ged/pluggability).

After checking out the source, run:

    $ rake newb

This task will install any missing dependencies, run the tests/specs,
and generate the API documentation.


## Authors

- Michael Granger <ged@faeriemud.org>
- Martin Chase <outofculture@gmail.com>


## License

Copyright (c) 2008-2020, Michael Granger and Martin Chase
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author/s, nor the names of the project's
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



