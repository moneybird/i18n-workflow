# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'i18n/workflow/version'

Gem::Specification.new do |spec|
  spec.name          = "i18n-workflow"
  spec.version       = I18n::Workflow::VERSION
  spec.authors       = ["Edwin Vlieg"]
  spec.email         = ["info@moneybird.com"]
  spec.summary       = %q{I18n workflow for faster development of multilanguage apps}
  spec.homepage      = "http://github.com/moneybird/i18n-workflow"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "ya2yaml"
  spec.add_dependency "i18n"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", ">= 2.2.33"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
