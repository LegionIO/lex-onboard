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
end
