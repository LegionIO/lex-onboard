# Changelog

## [0.1.1] - 2026-03-22

### Changed
- Add legion-logging, legion-settings, legion-json, legion-cache, legion-crypt, legion-data, and legion-transport as runtime dependencies
- Update spec_helper with real sub-gem helper stubs replacing manual Legion::Logging and Legion::Extensions::Core stubs

## [0.1.0] - 2026-03-21

### Added
- `Runners::Provision` with `provision` method for automated onboarding workflow
- Chains Vault namespace, Consul partition, TFE project creation, and Slack notification
- Per-step error handling with continue-on-failure semantics
- `Actor::Provision` subscription actor for AMQP-triggered provisioning
- Full RSpec test coverage (15 specs)
