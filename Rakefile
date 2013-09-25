#!/usr/bin/env rake

require 'hoe'

Hoe.plugin :deveiate
Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :bundler

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'pluggability' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files = Rake::FileList[ '*.rdoc' ]
	self.spec_extras[:rdoc_options] = ['-t', 'Pluggability Toolkit']

	self.developer 'Martin Chase', 'stillflame@FaerieMUD.org'
	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.dependency 'loggability', '~> 0.7'

	self.dependency 'hoe-deveiate', '~> 0.3', :development
	self.dependency 'hoe-bundler', '~> 1.2', :development

	self.license "BSD"
	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags= )
	self.check_history_on_release = true if self.respond_to?( :check_history_on_release= )
	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

task 'hg:precheckin' => [ :check_history, :check_manifest, :spec ]

