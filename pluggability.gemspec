# -*- encoding: utf-8 -*-
# stub: pluggability 0.5.0.pre20171120144102 ruby lib

Gem::Specification.new do |s|
  s.name = "pluggability".freeze
  s.version = "0.5.0.pre20171120144102"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Martin Chase".freeze, "Michael Granger".freeze]
  s.date = "2017-11-20"
  s.description = "Pluggability is a toolkit for creating plugins.\n\nIt provides a mixin that extends your class with methods to load and instantiate its subclasses by name. So instead of:\n\n    require 'acme/adapter/png'\n    png_adapter = Acme::Adapter::PNG.new( 'file.png' )\n  \nyou can do:\n\n    require 'acme/adapter'\n    png_adapter = Acme::Adapter.create( :png, 'file.png' )\n\nA full example of where this might be useful is in a program which generates\noutput with a 'driver' object, which provides a unified interface but generates\ndifferent kinds of output.\n\nFirst the abstract base class, which is extended with Pluggability:\n\n    # in mygem/driver.rb:\n    require 'pluggability'\n    require 'mygem' unless defined?( MyGem )\n    \n    class MyGem::Driver\n        extend Pluggability\n        plugin_prefixes \"mygem/drivers\"\n    end\n\nWe can have one driver that outputs PDF documents:\n\n    # mygem/drivers/pdf.rb:\n    require 'mygem/driver' unless defined?( MyGem::Driver )\n    \n    class MyGem::Driver::PDF < Driver\n        ...implementation...\n    end\n\nand another that outputs plain ascii text:\n\n    #mygem/drivers/ascii.rb:\n    require 'mygem/driver' unless defined?( MyGem::Driver )\n    \n    class MyGem::Driver::ASCII < Driver\n        ...implementation...\n    end\n\nNow the driver is configurable by the end-user, who can just set\nit by its short name:\n\n    require 'mygem'\n    \n    config[:driver_type] #=> \"pdf\"\n    driver = MyGem::Driver.create( config[:driver_type] )\n    driver.class #=> MyGem::Driver::PDF\n\n    # You can also pass arguments to the constructor, too:\n    ascii_driver = MyGem::Driver.create( :ascii, :columns => 80 )".freeze
  s.email = ["stillflame@FaerieMUD.org".freeze, "ged@FaerieMUD.org".freeze]
  s.extra_rdoc_files = ["History.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "History.md".freeze, "README.md".freeze]
  s.files = ["ChangeLog".freeze, "History.md".freeze, "Manifest.txt".freeze, "README.md".freeze, "Rakefile".freeze, "lib/pluggability.rb".freeze, "spec/helpers.rb".freeze, "spec/pluggability_spec.rb".freeze]
  s.homepage = "http://deveiate.org/projects/pluggability".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.4".freeze)
  s.rubygems_version = "2.6.13".freeze
  s.summary = "Pluggability is a toolkit for creating plugins".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.12"])
      s.add_development_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 5.1"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.16"])
    else
      s.add_dependency(%q<loggability>.freeze, ["~> 0.12"])
      s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
      s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 5.1"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
    end
  else
    s.add_dependency(%q<loggability>.freeze, ["~> 0.12"])
    s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.9"])
    s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 5.1"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.16"])
  end
end
