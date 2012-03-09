# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mockingbird/version"

Gem::Specification.new do |s|
  s.name        = "mockingbird"
  s.version     = Mockingbird::VERSION
  s.authors     = ["Josh Cheek"]
  s.email       = ["josh.cheek@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Framework to ad in handrolling mock/spy objects.}
  s.description = %q{Framework to ad in handrolling mock/spy objects.}

  s.rubyforge_project = "cobbler"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
