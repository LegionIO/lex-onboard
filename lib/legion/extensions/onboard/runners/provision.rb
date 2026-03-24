# frozen_string_literal: true

module Legion
  module Extensions
    module Onboard
      module Runners
        module Provision
          include Validator

          def provision(askid:, tfe_organization: 'terraform.uhg.com', requester_slack_webhook: nil, **)
            steps = []

            steps << vault_namespace(askid: askid)
            steps << consul_partition(askid: askid)
            steps << tfe_project(askid: askid, organization: tfe_organization)

            failed = steps.any? { |s| s[:status] == 'error' }
            notify_requester(askid: askid, webhook: requester_slack_webhook) if requester_slack_webhook

            {
              status: failed ? 'failed' : 'completed',
              askid: askid,
              steps: steps
            }
          end

          private

          def vault_namespace(askid:)
            return { step: :vault_namespace, status: 'skipped', reason: 'vault unavailable' } unless defined?(Legion::Extensions::Vault::Client)
            return { step: :vault_namespace, status: 'skipped', reason: 'already exists' } if vault_exists?(askid)

            vault_client.create_namespace(name: askid)
            { step: :vault_namespace, status: 'completed', askid: askid }
          rescue StandardError => e
            { step: :vault_namespace, status: 'error', error: e.message }
          end

          def consul_partition(askid:)
            return { step: :consul_partition, status: 'skipped', reason: 'consul unavailable' } unless defined?(Legion::Extensions::Consul::Client)
            return { step: :consul_partition, status: 'skipped', reason: 'already exists' } if consul_exists?(askid)

            consul_client.create_partition(name: askid)
            { step: :consul_partition, status: 'completed', askid: askid }
          rescue StandardError => e
            { step: :consul_partition, status: 'error', error: e.message }
          end

          def tfe_project(askid:, organization:)
            return { step: :tfe_project, status: 'skipped', reason: 'tfe unavailable' } unless defined?(Legion::Extensions::Tfe::Client)
            return { step: :tfe_project, status: 'skipped', reason: 'already exists' } if tfe_exists?(askid)

            tfe_client.create_project(organization: organization, name: askid)
            { step: :tfe_project, status: 'completed', askid: askid }
          rescue StandardError => e
            { step: :tfe_project, status: 'error', error: e.message }
          end

          def vault_client
            Legion::Extensions::Vault::Client.new
          end

          def consul_client
            Legion::Extensions::Consul::Client.new
          end

          def tfe_client
            Legion::Extensions::Tfe::Client.new
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
