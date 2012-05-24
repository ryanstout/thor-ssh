# -*- encoding: utf-8 -*-
require File.expand_path('../lib/thor-ssh/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ryan Stout"]
  gem.email         = ["ryanstout@gmail.com"]
  gem.description   = %q{Makes it so you can set a remote destination for thor's actions (via ssh/sftp)}
  gem.summary       = %q{Makes thor work with remote destinations}
  gem.homepage      = "https://github.com/ryanstout/thor-ssh"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "thor-ssh"
  gem.require_paths = ["lib"]
  gem.add_runtime_dependency 'thor', '~> 0.15.2'
  gem.add_runtime_dependency 'net-ssh'#, '= 2.2.2'
  gem.add_runtime_dependency 'net-sftp'#, '= 2.0.5'
  gem.add_development_dependency 'rspec', '~> 2.10'
  gem.add_development_dependency 'vagrant', '= 1.0.3'
  gem.add_development_dependency 'sahara'
  gem.add_development_dependency 'rake', '~> 0.9'
  gem.add_development_dependency 'rdoc', '~> 3.9'
  gem.rdoc_options = ['--charset=UTF-8']
  
  gem.version       = ThorSsh::VERSION
end
