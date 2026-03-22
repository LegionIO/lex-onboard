# frozen_string_literal: true

module Legion
  module Extensions
    module Onboard
      module Actor
        class Provision < Legion::Extensions::Actors::Subscription
          def runner_class
            'Legion::Extensions::Onboard::Runners::Provision'
          end

          def runner_function
            'provision'
          end

          def use_runner?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end
        end
      end
    end
  end
end
