# frozen_string_literal: true

module Legion
  module Extensions
    module Onboard
      module Runners
        module Provision
          def provision(askid:, tfe_organization: 'terraform.uhg.com', requester_slack_webhook: nil, **)
            steps = []

            steps << run_step('vault_namespace') { create_vault_namespace(name: askid) }
            steps << run_step('consul_partition') { create_consul_partition(name: askid) }
            steps << run_step('tfe_project') { create_tfe_project(name: askid, organization: tfe_organization) }
            steps << run_step('notify') { notify_requester(askid: askid, webhook: requester_slack_webhook) }

            failed = steps.any? { |s| s[:status] == 'error' }

            {
              status: failed ? 'failed' : 'completed',
              askid: askid,
              steps: steps
            }
          end

          private

          def run_step(name)
            yield
            { name: name, status: 'ok' }
          rescue StandardError => e
            { name: name, status: 'error', error: e.message }
          end

          def create_vault_namespace(name:)
            return { result: false } unless defined?(Legion::Extensions::Vault::Client)

            Legion::Extensions::Vault::Client.new.create_namespace(name: name)
          end

          def create_consul_partition(name:)
            return { result: false } unless defined?(Legion::Extensions::Consul::Client)

            Legion::Extensions::Consul::Client.new.create_partition(name: name)
          end

          def create_tfe_project(name:, organization:)
            return { result: false } unless defined?(Legion::Extensions::Tfe::Client)

            Legion::Extensions::Tfe::Client.new.create_project(organization: organization, name: name)
          end

          def notify_requester(askid:, webhook: nil)
            return true unless webhook && defined?(Legion::Extensions::Slack::Client)

            Legion::Extensions::Slack::Client.new.send_webhook(
              webhook: webhook, message: "Onboarding complete for #{askid}"
            )
          rescue StandardError
            true
          end
        end
      end
    end
  end
end
