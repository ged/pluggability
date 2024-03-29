# -*- encoding: utf-8 -*-
# stub: pluggability 0.10.0.pre.20230608081829 ruby lib

Gem::Specification.new do |s|
  s.name = "pluggability".freeze
  s.version = "0.10.0.pre.20230608081829"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://todo.sr.ht/~ged/Pluggability/browse", "changelog_uri" => "https://deveiate.org/code/pluggability/History_md.html", "documentation_uri" => "https://deveiate.org/code/pluggability", "homepage_uri" => "https://hg.sr.ht/~ged/Pluggability", "source_uri" => "https://hg.sr.ht/~ged/Pluggability/browse" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze, "Martin Chase".freeze]
  s.date = "2023-06-08"
  s.description = "Pluggability is a toolkit for creating plugins.".freeze
  s.email = ["ged@faeriemud.org".freeze, "outofculture@gmail.com".freeze]
  s.files = ["History.md".freeze, "README.md".freeze, "lib/pluggability.rb".freeze, "spec/helpers.rb".freeze, "spec/pluggability_spec.rb".freeze]
  s.homepage = "https://hg.sr.ht/~ged/Pluggability".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rubygems_version = "3.3.26".freeze
  s.summary = "Pluggability is a toolkit for creating plugins.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<loggability>.freeze, ["~> 0.15"])
    s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.21"])
    s.add_development_dependency(%q<rdoc-generator-sixfish>.freeze, ["~> 0.2"])
  else
    s.add_dependency(%q<loggability>.freeze, ["~> 0.15"])
    s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.21"])
    s.add_dependency(%q<rdoc-generator-sixfish>.freeze, ["~> 0.2"])
  end
end
