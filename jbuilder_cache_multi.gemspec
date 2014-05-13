# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jbuilder_cache_multi/version'

Gem::Specification.new do |spec|
  spec.name          = "jbuilder_cache_multi"
  spec.version       = JbuilderCacheMulti::VERSION
  spec.authors       = ["Yonah Forst"]
  spec.email         = ["joshblour@hotmail.com"]
  spec.summary       = %q{Adds cache_collection! to jbuilder. Uses memcache fetch_multi/read_multi}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency 'jbuilder', '~> 2.0'
  
end
