# frozen_string_literal: true

require_relative 'lib/legion/extensions/onboard/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-onboard'
  spec.version       = Legion::Extensions::Onboard::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX::Onboard'
  spec.description   = 'Automated onboarding: Vault namespace, Consul partition, TFE project provisioning'
  spec.homepage      = 'https://github.com/LegionIO'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'legion-cache', '>= 1.3.11'
  spec.add_dependency 'legion-crypt', '>= 1.4.9'
  spec.add_dependency 'legion-data', '>= 1.4.17'
  spec.add_dependency 'legion-json', '>= 1.2.1'
  spec.add_dependency 'legion-logging', '>= 1.3.2'
  spec.add_dependency 'legion-settings', '>= 1.3.14'
  spec.add_dependency 'legion-transport', '>= 1.3.9'
end
