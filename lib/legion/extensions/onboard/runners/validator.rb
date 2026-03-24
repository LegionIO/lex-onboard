# frozen_string_literal: true

module Legion
  module Extensions
    module Onboard
      module Runners
        module Validator
          ASKID_PATTERN = /\A[a-z0-9]([a-z0-9-]*[a-z0-9])?\z/
          MAX_ASKID_LENGTH = 63

          def validate_askid(askid:)
            return { valid: false, reason: 'askid is empty' } if askid.nil? || askid.empty?
            return { valid: false, reason: "askid exceeds #{MAX_ASKID_LENGTH} characters" } if askid.length > MAX_ASKID_LENGTH

            unless askid.match?(ASKID_PATTERN)
              return { valid: false,
                       reason: 'askid format invalid — must be lowercase alphanumeric with hyphens' }
            end

            { valid: true }
          end

          def check_conflicts(askid:)
            conflicts = []
            conflicts << :vault if vault_exists?(askid)
            conflicts << :consul if consul_exists?(askid)
            conflicts << :tfe if tfe_exists?(askid)

            { conflicts: conflicts, askid: askid }
          end

          private

          def vault_exists?(askid)
            return false unless defined?(Legion::Extensions::Vault::Client)

            Legion::Extensions::Vault::Client.new.list_namespaces[:namespaces]&.include?(askid)
          rescue StandardError
            false
          end

          def consul_exists?(askid)
            return false unless defined?(Legion::Extensions::Consul::Client)

            Legion::Extensions::Consul::Client.new.list_partitions[:partitions]&.any? { |p| p[:name] == askid }
          rescue StandardError
            false
          end

          def tfe_exists?(askid)
            return false unless defined?(Legion::Extensions::Tfe::Client)

            Legion::Extensions::Tfe::Client.new.list_projects[:projects]&.any? { |p| p[:name] == askid }
          rescue StandardError
            false
          end
        end
      end
    end
  end
end
