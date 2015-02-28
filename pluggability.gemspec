# -*- encoding: utf-8 -*-
# stub: pluggability 0.5.0.pre20150227193939 ruby lib

Gem::Specification.new do |s|
  s.name = "pluggability"
  s.version = "0.5.0.pre20150227193939"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Martin Chase", "Michael Granger"]
  s.date = "2015-02-28"
  s.description = "Pluggability is a mixin module that turns an including class into a\nfactory for its derivatives, capable of searching for and loading them\nby name. This is useful when you have an abstract base class which\ndefines an interface and basic functionality for a part of a larger\nsystem, and a collection of subclasses which implement the interface for\ndifferent underlying functionality.\n\nAn example of where this might be useful is in a program which generates\noutput with a 'driver' object, which provides a unified interface but\ngenerates different kinds of output.\n\nFirst the abstract base class, which is extended with Pluggability:\n\n    # in mygem/driver.rb:\n    require 'pluggability'\n    require 'mygem' unless defined?( MyGem )\n    \n    class MyGem::Driver\n        extend Pluggability\n        plugin_prefixes \"drivers\", \"drivers/compat\"\n    end\n\nWe can have one driver that outputs PDF documents:\n\n    # mygem/drivers/pdf.rb:\n    require 'mygem/driver' unless defined?( MyGem::Driver )\n    \n    class MyGem::Driver::PDF < Driver\n        ...implementation...\n    end\n\nand another that outputs plain ascii text:\n\n    #mygem/drivers/ascii.rb:\n    require 'mygem/driver' unless defined?( MyGem::Driver )\n    \n    class MyGem::Driver::ASCII < Driver\n        ...implementation...\n    end\n\nNow the driver is configurable by the end-user, who can just set\nit by its short name:\n\n    require 'mygem'\n    \n    config[:driver_type] #=> \"pdf\"\n    driver = MyGem::Driver.create( config[:driver_type] )\n    driver.class #=> MyGem::Driver::PDF\n\n    # You can also pass arguments to the constructor, too:\n    ascii_driver = MyGem::Driver.create( :ascii, :columns => 80 )"
  s.email = ["stillflame@FaerieMUD.org", "ged@FaerieMUD.org"]
  s.extra_rdoc_files = ["History.rdoc", "Manifest.txt", "README.rdoc", "History.rdoc", "README.rdoc"]
  s.files = ["ChangeLog", "History.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "lib/pluggability.rb", "spec/helpers.rb", "spec/pluggability_spec.rb"]
  s.homepage = "https://bitbucket.org/ged/pluggability"
  s.licenses = ["BSD"]
  s.rdoc_options = ["-t", "Pluggability Toolkit", "-f", "fivefish"]
  s.rubygems_version = "2.4.5"
  s.signing_key = "/Volumes/Keys/ged-private_gem_key.pem"
  s.summary = "Pluggability is a mixin module that turns an including class into a factory for its derivatives, capable of searching for and loading them by name"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<loggability>, ["~> 0.8"])
      s.add_development_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>, ["~> 0.6"])
      s.add_development_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_development_dependency(%q<hoe>, ["~> 3.13"])
    else
      s.add_dependency(%q<loggability>, ["~> 0.8"])
      s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>, ["~> 0.6"])
      s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_dependency(%q<hoe>, ["~> 3.13"])
    end
  else
    s.add_dependency(%q<loggability>, ["~> 0.8"])
    s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>, ["~> 0.6"])
    s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
    s.add_dependency(%q<hoe>, ["~> 3.13"])
  end
end
