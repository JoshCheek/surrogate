# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "surrogate/version"

Gem::Specification.new do |s|
  s.name        = "surrogate"
  s.version     = Surrogate::VERSION
  s.authors     = ["Josh Cheek"]
  s.email       = ["josh.cheek@gmail.com"]
  s.homepage    = "https://github.com/JoshCheek/surrogate"
  s.summary     = %q{Framework to aid in handrolling mock/spy objects.}
  s.description = %q{Framework to aid in handrolling mock/spy objects.}

  s.rubyforge_project = "surrogate"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'bindable_block', '= 0.0.5.1'

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec",                                "~> 2.2"
  s.add_development_dependency "mountain_berry_fields",                "~> 1.0.3"
  s.add_development_dependency "mountain_berry_fields-rspec",          "~> 1.0.2"
  s.add_development_dependency "mountain_berry_fields-magic_comments", "~> 1.0.1"
end
