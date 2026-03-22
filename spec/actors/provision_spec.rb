# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/onboard/actors/provision'

RSpec.describe Legion::Extensions::Onboard::Actor::Provision do
  subject(:actor) { described_class.allocate }

  describe '#runner_class' do
    it 'returns the provision runner class string' do
      expect(actor.runner_class).to eq('Legion::Extensions::Onboard::Runners::Provision')
    end
  end

  describe '#runner_function' do
    it 'returns provision' do
      expect(actor.runner_function).to eq('provision')
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(actor.use_runner?).to be false
    end
  end

  describe '#check_subtask?' do
    it 'returns false' do
      expect(actor.check_subtask?).to be false
    end
  end

  describe '#generate_task?' do
    it 'returns false' do
      expect(actor.generate_task?).to be false
    end
  end
end
