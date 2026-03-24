# frozen_string_literal: true

module Legion
  module Extensions
    module Onboard
      module Runners
        module Provision
          include Validator

          ROLLBACK_ACTIONS = {
            vault_namespace: ->(client, askid) { client.delete_namespace(name: askid) },
            consul_partition: ->(client, askid) { client.delete_partition(name: askid) },
            tfe_project: ->(client, askid) { client.delete_project(name: askid) }
          }.freeze

          def provision(askid:, tfe_organization: 'terraform.uhg.com', requester_slack_webhook: nil, **)
            validation = validate_askid(askid: askid)
            return { status: 'rejected', askid: askid, reason: validation[:reason] } unless validation[:valid]

            conflicts = check_conflicts(askid: askid)
            unless conflicts[:conflicts].empty?
              return { status: 'rejected', askid: askid, reason: "conflict in: #{conflicts[:conflicts].join(', ')}" }
            end

            completed_steps = []
            steps = []

            %i[vault_namespace consul_partition tfe_project].each do |step_name|
              result = run_step(step_name, askid: askid, tfe_organization: tfe_organization)
              steps << result

              if result[:status] == 'error'
                rollback_results = rollback(completed_steps, askid: askid)
                return { status: 'failed', askid: askid, steps: steps, rollback: rollback_results }
              end

              completed_steps << step_name if result[:status] == 'completed'
            end

            notify_requester(askid: askid, webhook: requester_slack_webhook) if requester_slack_webhook
            { status: 'completed', askid: askid, steps: steps, rollback: [] }
          end

          private

          def run_step(step_name, askid:, tfe_organization:)
            case step_name
            when :vault_namespace then vault_namespace(askid: askid)
            when :consul_partition then consul_partition(askid: askid)
            when :tfe_project then tfe_project(askid: askid, organization: tfe_organization)
            end
          end

          def rollback(completed_steps, askid:)
            completed_steps.reverse.map do |step_name|
              action = ROLLBACK_ACTIONS[step_name]
              next unless action

              action.call(client_for_step(step_name), askid)
              { step: step_name, status: 'rolled_back' }
            rescue StandardError => e
              { step: step_name, status: 'rollback_failed', error: e.message }
            end.compact
          end

          def client_for_step(step_name)
            case step_name
            when :vault_namespace then vault_client
            when :consul_partition then consul_client
            when :tfe_project then tfe_client
            end
          end

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
