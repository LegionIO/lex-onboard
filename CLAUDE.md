# lex-onboard

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Automated team onboarding for LegionIO. Provisions three infrastructure resources in sequence — Vault namespace, Consul partition, and TFE project — under a single `askid` identifier, following the Grid immutable naming rule (`askid == Vault namespace == Consul partition == TFE project`).

## Gem Info

- **Gem name**: `lex-onboard`
- **Version**: `0.2.0`
- **Module**: `Legion::Extensions::Onboard`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/onboard/
  version.rb
  runners/
    provision.rb   # provision(askid:, tfe_organization:, requester_slack_webhook:)
  actors/
    provision.rb   # Subscription actor on onboard.provision queue
spec/
  runners/
    provision_spec.rb
  actors/
    provision_spec.rb
```

## Runner: `Runners::Provision`

### `provision(askid:, tfe_organization: 'terraform.uhg.com', requester_slack_webhook: nil)`

Runs four steps sequentially, capturing the result of each:

1. `vault_namespace` — calls `Legion::Extensions::Vault::Client.new.create_namespace(name: askid)` if `lex-vault` is loaded; skips otherwise
2. `consul_partition` — calls `Legion::Extensions::Consul::Client.new.create_partition(name: askid)` if `lex-consul` is loaded; skips otherwise
3. `tfe_project` — calls `Legion::Extensions::Tfe::Client.new.create_project(organization:, name:)` if `lex-tfe` is loaded; skips otherwise
4. `notify` — sends Slack webhook completion message if `requester_slack_webhook` is set and `lex-slack` is loaded

Returns:
```ruby
{
  status: 'completed' | 'failed',
  askid: askid,
  steps: [{ name: 'vault_namespace', status: 'ok' | 'error', error: '...' }, ...]
}
```

Each step is wrapped in `run_step` which rescues `StandardError` — a single failure sets overall `status: 'failed'` but allows subsequent steps to run.

## Actor: `Actor::Provision`

Subscription actor on the `onboard.provision` queue. Routes to `Runners::Provision#provision`.

## Integration Points

- **lex-vault** (`extensions/`): `create_namespace` call
- **lex-consul** (`extensions/`): `create_partition` call
- **lex-tfe** (`extensions/`): `create_project` call
- **lex-slack** (`extensions-other/`): completion notification (optional)

## Development Notes

- All external calls are guarded with `defined?()` — the gem is standalone and never raises on missing dependencies; it skips the step and returns `{ result: false }`
- `tfe_organization` defaults to `terraform.uhg.com` (UHG app team TFE cluster, not `tfe-arc.uhg.com` which is platform)
- No DB required (`data_required?` is not overridden, defaults to framework setting)
