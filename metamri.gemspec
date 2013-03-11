# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "metamri/version"

Gem::Specification.new do |s|
  s.name = %q{metamri}
  s.version = Metamri::VERSION

  s.authors = ["Kristopher J. Kosmatka", "Erik Kastman"]
  s.summary = %q{MRI metadata}
  s.description = %q{Extraction of MRI metadata.}
  s.email = %q{ekk@medicine.wisc.edu}
  s.homepage = %q{http://github.com/brainmap/metamri}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency('dicom', "~> 0.8.0")
  s.add_runtime_dependency('activeresource', "~> 3.0")
  s.add_runtime_dependency('rmagick', ">= 2.13.1") # ??? changed from  "~> 2.13.1") 
  s.add_runtime_dependency('hirb', "~> 0.4")
  s.add_runtime_dependency('sqlite3', "~>1.3.4")
  s.add_development_dependency('rspec', "~> 2.5")
  s.add_development_dependency('escoffier', ">= 0")
  
end

