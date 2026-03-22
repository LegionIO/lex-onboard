# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
SimpleCov.start

module Legion
  module Logging
    def self.debug(_msg); end

    def self.info(_msg); end

    def self.warn(_msg); end

    def self.error(_msg); end
  end

  module Extensions
    module Core; end

    module Actors
      class Every; end

      class Subscription; end
    end
  end

  module Settings
    @store = {}

    class << self
      def [](key)
        @store[key.to_sym] ||= {}
      end

      def []=(key, val)
        @store[key.to_sym] = val
      end

      def reset!
        @store = {}
      end
    end
  end
end

require 'legion/extensions/onboard'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
