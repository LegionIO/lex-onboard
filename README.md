# lex-onboard

Automated team onboarding for LegionIO: provisions Vault namespace, Consul partition, and TFE project in a single workflow.

## Usage

```ruby
provisioner = Class.new { include Legion::Extensions::Onboard::Runners::Provision }.new

result = provisioner.provision(
  askid: 'app-12345',
  tfe_organization: 'terraform.uhg.com',
  requester_slack_webhook: '/services/T/B/x'
)
# => { status: 'completed', askid: 'app-12345', steps: [...] }
```

## Dependencies

- `lex-vault` (>= 0.1.2) for namespace creation
- `lex-consul` (>= 0.1.1) for partition creation
- `lex-tfe` for TFE project creation
- `lex-slack` (optional) for completion notification

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```
