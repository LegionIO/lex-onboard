# Changelog

## [0.2.0] - 2026-03-24

### Added
- `Runners::Validator` with `validate_askid` (lowercase, max 63 chars, alphanumeric-hyphen) and `check_conflicts` (Vault/Consul/TFE existence checks)
- Idempotent step guards — each provisioning step checks if the resource already exists and skips creation if so
- Reverse-order rollback on provisioning step failure — completed steps are unwound via `delete_namespace`, `delete_partition`, `delete_project`
- Validation and conflict detection wired into `provision` entry point — rejects before any steps run

### Fixed
- Slack `send_webhook` parameter mismatch (`text:` changed to `message:`)

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
